# Grafana Tempo — Distributed Trace Backend

Tempo stores distributed traces produced by the OTel collector sidecar in `observability/opentelemetry/`. It is the trace backend referenced by the `otlp/tempo` exporter in `collector-config.yaml` and the `tracesToLogsV2` link in `loki/grafana-datasource.yaml`.

---

## Installation

Add the Grafana chart repository:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install in the same `monitoring` namespace as Prometheus and Loki:

```bash
helm install tempo grafana/tempo \
  --version 1.9.0 \
  --namespace monitoring \
  --create-namespace \
  -f observability/tempo/values.yaml
```

After installation, apply the Grafana datasource ConfigMap so Grafana discovers Tempo automatically:

```bash
kubectl apply -f observability/tempo/grafana-datasource.yaml
```

> **Note:** For the datasource ConfigMap to be picked up automatically, the Grafana Helm release must have `sidecar.datasources.enabled: true`. Add the following to `observability/prometheus/values.yaml` under the `grafana:` key and then upgrade:
>
> ```yaml
> grafana:
>   sidecar:
>     datasources:
>       enabled: true
>       searchNamespace: ALL
>       label: grafana_datasource
>       labelValue: "1"
> ```
>
> ```bash
> helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
>   --namespace monitoring -f observability/prometheus/values.yaml
> ```

---

## Architecture: Where Tempo Sits

```
Application Pod
  └── OTel Collector Sidecar (observability/opentelemetry/collector-config.yaml)
        receivers:  otlp  ←── App SDK (OTLP gRPC :4317)
        exporters:
          otlp/tempo ──────────────────────────────────► Tempo (:4317 gRPC)
                                                          └── stores trace blocks
          prometheusremotewrite ──────────────────────► Prometheus

Grafana Explore
  ├── trace search ──────────────────────────────────► Tempo :3200 (query API)
  ├── span → log correlation ────────────────────────► Loki (via tracesToLogsV2)
  └── span → RED metrics ────────────────────────────► Prometheus (via tracesToMetrics)
```

**Bi-directional correlation with Loki:**

| Starting point | Click | Destination |
|----------------|-------|-------------|
| Loki log line containing `trace_id` | "View trace" | Tempo waterfall |
| Tempo span | "Logs for this span" | Loki query filtered by `trace_id` |

This link works because:
- Promtail extracts `trace_id` from structured log lines and promotes it as a Loki label (configured in `observability/loki/values.yaml`)
- The Loki datasource's `derivedFields` matches that label and generates a Tempo link
- The Tempo datasource's `tracesToLogsV2` maps back into Loki when exploring a trace

---

## Verify Installation

```bash
# Check the pod is running
kubectl -n monitoring get pods -l app.kubernetes.io/name=tempo

# Check Tempo's own metrics endpoint
kubectl -n monitoring port-forward svc/tempo 3200:3200
curl http://localhost:3200/metrics | grep tempo_ingester

# Send a test trace via OTLP HTTP to confirm ingest works
curl -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  -d '{"resourceSpans":[]}'
# Expected: HTTP 200 with an empty response body

# Search for traces in the last hour
curl "http://localhost:3200/api/search?limit=5&start=$(date -d '-1 hour' +%s)&end=$(date +%s)"
```

---

## Query Traces with TraceQL

TraceQL is Tempo's trace query language. Use it in Grafana Explore → Tempo → TraceQL tab.

```traceql
# Find all traces with an HTTP 5xx status in the last 1 hour
{ span.http.response.status_code >= 500 }

# Find traces from a specific service taking longer than 2 seconds
{ resource.service.name = "my-service" && duration > 2s }

# Find error spans from a specific operation
{ name = "POST /api/orders" && status = error }

# Aggregate: P99 latency by service
{ } | rate() by (resource.service.name)
```

---

## Storage: Filesystem → Object Storage

The default `values.yaml` uses `backend: local` with a PersistentVolumeClaim. Before running in production, switch to an object storage backend for durability and horizontal scalability.

**S3 example** — add under `tempo.storage.trace` in `values.yaml`:

```yaml
tempo:
  storage:
    trace:
      backend: s3   # <-- CHANGE THIS
      s3:
        bucket: my-tempo-traces   # <-- CHANGE THIS
        region: us-east-1         # <-- CHANGE THIS
        access_key: ""            # <-- CHANGE THIS: use IRSA / Workload Identity instead
        secret_key: ""            # <-- CHANGE THIS: leave empty with IRSA / Workload Identity
        insecure: false
```

**GCS example:**

```yaml
tempo:
  storage:
    trace:
      backend: gcs   # <-- CHANGE THIS
      gcs:
        bucket_name: my-tempo-traces   # <-- CHANGE THIS
```

**Azure example:**

```yaml
tempo:
  storage:
    trace:
      backend: azure   # <-- CHANGE THIS
      azure:
        container_name: tempo-traces   # <-- CHANGE THIS
        account_name: ""               # <-- CHANGE THIS
        account_key: ""                # <-- CHANGE THIS: prefer Managed Identity
```

---

## Scaling Beyond Monolithic Mode

When ingestion exceeds ~10 000 spans/second or you need independent component scaling, migrate to `grafana/tempo-distributed`. This splits the distributor, ingester, querier, compactor, and query-frontend into separate Deployments.

Indicators that monolithic mode is under pressure:

- Ingester memory regularly exceeds 80% of its limit
- `tempo_query_frontend_queries_total{result="failed"}` is non-zero
- Block compaction is consistently behind (metric: `tempo_compactor_block_retention_loops_duration_seconds > 300`)

See https://grafana.com/docs/tempo/latest/setup/helm-chart/ for the distributed chart values.
