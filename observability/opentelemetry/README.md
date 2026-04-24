# OpenTelemetry — Distributed Tracing, Metrics, and Logs

This directory contains the OTel collector sidecar patch, its configuration, and per-language
instrumentation environment variable files for .NET, Python, and Java.

---

## Three Signals

**Traces** capture the full journey of a request across service boundaries. Each trace is a tree
of spans, where each span records the start time, duration, and attributes of one operation (an
HTTP handler, a database query, an outgoing RPC). Traces are exported by application SDKs via OTLP
to the collector sidecar, which batches and forwards them to Tempo.

**Metrics** are numeric time-series: request rate, error count, P99 latency, JVM heap, and so on.
The collector forwards application OTLP metrics and its own self-metrics to Prometheus via
remote-write. The same data then powers the kube-prometheus-stack dashboards and alerting rules in
`observability/prometheus/`.

**Logs** are discrete events with structure. When the OTel SDK is configured as a log appender
(see the `OTEL_LOGS_EXPORTER` variable in the env files), each log record is enriched with the
active `trace_id` and `span_id`. Promtail promotes `trace_id` as a Loki label, so in Grafana you
can jump from a trace span directly to the correlated log lines in Loki.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│               Kubernetes Pod                │
│                                             │
│  ┌──────────────────┐  OTLP gRPC/HTTP       │
│  │   App container  │──────────────────┐    │
│  │  (:8080)         │  localhost:4317  │    │
│  └──────────────────┘                  │    │
│                                        ▼    │
│  ┌────────────────────────────────────────┐ │
│  │       OTel Collector Sidecar           │ │
│  │                                        │ │
│  │  receivers:  otlp (4317/4318)          │ │
│  │              prometheus (self, 8888)   │ │
│  │                                        │ │
│  │  processors: memory_limiter            │ │
│  │              resource (k8s labels)     │ │
│  │              filter/exclude_health     │ │
│  │              batch                     │ │
│  │                                        │ │
│  │  exporters:  otlp/tempo ──────────────────► Tempo
│  │              prometheusremotewrite ───────► Prometheus
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## Installation Order

1. **Apply the collector ConfigMap** (must exist before the pod starts):
   ```bash
   kubectl apply -f observability/opentelemetry/collector-config.yaml -n <namespace>
   ```

2. **Patch the target Deployment** to add the sidecar:
   ```bash
   kubectl patch deployment <name> -n <namespace> \
     --patch-file observability/opentelemetry/collector-sidecar.yaml
   ```
   Or reference it as a `patchesStrategicMerge` entry in your `kustomization.yaml`.

3. **Load language-specific env vars** into your application container using one of:
   ```yaml
   # Kubernetes envFrom (preferred — values stay in a ConfigMap or Secret)
   envFrom:
     - configMapRef:
         name: otel-dotnet-env   # or otel-python-env / otel-java-env
   ```
   Create the ConfigMap from the env file:
   ```bash
   kubectl create configmap otel-dotnet-env \
     --from-env-file=observability/opentelemetry/env-vars/dotnet.env \
     -n <namespace>
   ```

---

## Language Instrumentation

| Runtime | Env file | Key step |
|---------|----------|----------|
| .NET (ASP.NET Core) | [env-vars/dotnet.env](env-vars/dotnet.env) | Add `OpenTelemetry.Extensions.Hosting` NuGet package and register in `Program.cs` |
| Python (FastAPI) | [env-vars/python.env](env-vars/python.env) | Prefix the uvicorn command with `opentelemetry-instrument` |
| Java (Spring Boot) | [env-vars/java.env](env-vars/java.env) | Add `-javaagent:/app/opentelemetry-javaagent.jar` before `-jar app.jar` in ENTRYPOINT |

Each env file includes step-by-step installation instructions in its comment header.

---

## Verify the Sidecar

After deployment, check the collector sidecar logs:

```bash
# Tail the collector's log stream
kubectl logs <pod-name> -c otel-collector -n <namespace> -f

# Confirm spans are being received and exported
kubectl logs <pod-name> -c otel-collector -n <namespace> | grep -E "Traces|spans|error"

# Check pipeline metrics (collector self-metrics scraped by Prometheus)
kubectl port-forward pod/<pod-name> 8888:8888 -n <namespace>
curl http://localhost:8888/metrics | grep otelcol
```

If the collector is not starting, check the readiness probe:

```bash
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 "otel-collector"
```

---

## Sampling Strategy

| Environment | `OTEL_TRACES_SAMPLER_ARG` | Rationale |
|-------------|--------------------------|-----------|
| dev / local | `1.0` | 100% — every request is traced to make debugging straightforward |
| staging | `0.5` | 50% — enough coverage to catch integration issues without full storage cost |
| production | `0.1` | 10% — statistically representative sample for latency and error analysis |

The `parentbased_traceidratio` sampler ensures that a sampling decision made at the edge
(e.g. by an ingress controller or the first service) is propagated to all downstream services,
keeping traces complete even when only a fraction of requests are sampled. Adjust the production
ratio up if you need to capture rare, intermittent errors.

Health probe spans (`/health`, `/health/ready`, `/health/live`) are dropped at the collector
level by the `filter/exclude_health` processor regardless of the sampling ratio, so they never
occupy storage in Tempo.

---

## Viewing Traces in Grafana

1. Ensure the Tempo datasource is added to Grafana. Add a new datasource:
   - Type: **Tempo**
   - URL: `http://tempo:3100` (or your Tempo service address) — `# <-- CHANGE THIS`
   - Enable **Trace to logs** and set the Loki datasource UID to cross-link spans to log lines.

2. Open **Explore** in Grafana, select the Tempo datasource, and search by:
   - Service name: the value of `OTEL_SERVICE_NAME` in your env file
   - Trace ID: copy from a log line's `trace_id` field in Loki

3. For a pre-built trace analysis dashboard, import the [Tempo / OpenTelemetry dashboard](https://grafana.com/grafana/dashboards/16611)
   from grafana.com.

---

## Updating the Collector Version

The collector version is pinned in [collector-sidecar.yaml](collector-sidecar.yaml).
Review release notes at <https://github.com/open-telemetry/opentelemetry-collector-releases>
and bump the image tag quarterly. After updating:

1. Review the changelog for breaking pipeline configuration changes.
2. Update the image tag in `collector-sidecar.yaml`.
3. Re-apply the ConfigMap and patch: `kubectl rollout restart deployment/<name> -n <namespace>`.
