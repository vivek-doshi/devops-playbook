# Loki Log Aggregation Stack

This directory contains Helm values for the `grafana/loki-stack` chart (version 2.10.x), which installs Loki and Promtail together. Loki stores log streams indexed by Kubernetes labels. Promtail runs as a DaemonSet on every node, tails pod and system logs, and ships them to Loki.

## Installation

Add the Grafana chart repository:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Install into the `monitoring` namespace alongside the Prometheus stack:

```bash
helm install loki grafana/loki-stack \
  --version 2.10.2 \
  --namespace monitoring \
  --create-namespace \
  -f observability/loki/values.yaml
```

After installation, apply the Grafana datasource ConfigMap so Grafana discovers Loki automatically:

```bash
kubectl apply -f observability/loki/grafana-datasource.yaml
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

## Import the Log Explorer Dashboard

The dashboard in `dashboards/log-explorer.json` can be imported into Grafana in two ways:

**Option A — Manual import:**
1. Open Grafana → Dashboards → Import.
2. Upload `dashboards/log-explorer.json` or paste its contents.
3. Select the `Loki` datasource when prompted.

**Option B — Automatic provisioning via sidecar:**
Create a ConfigMap from the JSON file labelled for the Grafana dashboard sidecar:

```bash
kubectl create configmap log-explorer-dashboard \
  --from-file=log-explorer.json=observability/loki/dashboards/log-explorer.json \
  --namespace monitoring \
  --dry-run=client -o yaml \
  | kubectl annotate --local -f - kubectl.kubernetes.io/last-applied-configuration= -o yaml \
  | kubectl label --local -f - grafana_dashboard=1 -o yaml \
  | kubectl apply -f -
```

## LogQL Basics

All examples below are copy-paste ready. Replace `<namespace>` and `<pod>` with real values or use the dashboard variables.

**Show all logs from a namespace:**

```logql
{namespace="<namespace>"}
```

**Filter to error logs only (works for both JSON-structured and plain-text logs):**

```logql
{namespace="<namespace>"} |= "error"
```

**Parse JSON logs and filter by the `level` field (FastAPI / structured Python apps):**

```logql
{namespace="<namespace>", app="<app-label>"} | json | level="error"
```

**Count error log lines per minute for a pod prefix over the last hour:**

```logql
sum(rate({namespace="<namespace>", pod=~"<pod-prefix>.*"} | json | level="error" [1m]))
```

**Extract and display only the `message` field from JSON logs:**

```logql
{namespace="<namespace>"} | json | line_format "{{.message}}"
```

## Add a New Pipeline Stage for a Custom Log Format

Pipeline stages are defined under `promtail.config.snippets.pipelineStages` in `values.yaml`. Each stage runs in order against every log line before it is sent to Loki.

To add parsing for a custom format, add a `match` stage with a selector that targets the app's labels:

```yaml
promtail:
  config:
    snippets:
      pipelineStages:
        # ... existing stages ...
        - match:
            selector: '{app="my-custom-app"}'
            stages:
              - regex:
                  # Parse "LEVEL timestamp message" format
                  expression: '^(?P<level>\w+) (?P<ts>\S+) (?P<message>.*)$'
              - timestamp:
                  source: ts
                  format: RFC3339Nano
              - labels:
                  level:
```

After editing, upgrade the release:

```bash
helm upgrade loki grafana/loki-stack \
  --version 2.10.2 \
  --namespace monitoring \
  -f observability/loki/values.yaml
```

## Increase Retention or Switch to Object Storage

**Change retention period to 90 days:**

```yaml
loki:
  config:
    limits_config:
      retention_period: 2160h   # 90 days
      max_query_length: 2161h   # 90 days + 1 hour buffer
```

Also increase `loki.persistence.size` before applying — 90 days typically requires at least 150 Gi for a mid-size cluster.

**Switch to S3 object storage:**

```yaml
loki:
  config:
    common:
      storage:
        s3:
          bucketnames: my-loki-chunks-bucket   # <-- CHANGE THIS
          region: us-east-1                    # <-- CHANGE THIS
          # Prefer IRSA on EKS over static credentials.
          # See docs/guides/secrets-management.md
    schema_config:
      configs:
        - from: "2024-01-01"
          store: tsdb
          object_store: s3      # <-- CHANGE THIS from filesystem
          schema: v13
          index:
            prefix: index_
            period: 24h
```

For GCS, replace `s3:` with `gcs: { bucket_name: my-bucket }`. For Azure, use `azure: { account_name: ..., container: ... }`.

## Common Issues

**Promtail cannot read container logs (permission denied)**

```bash
kubectl logs -n monitoring -l app=promtail --tail=50
```

If you see `permission denied` errors against `/var/log/pods/`, add the `DAC_READ_SEARCH` capability:

```yaml
promtail:
  containerSecurityContext:
    readOnlyRootFilesystem: true
    capabilities:
      drop: [ALL]
      add: [DAC_READ_SEARCH]
```

**Log rate limiting — `429 Too Many Requests` from Loki**

Raise the ingestion rate ceiling in `values.yaml`:

```yaml
loki:
  config:
    limits_config:
      ingestion_rate_mb: 32
      ingestion_burst_size_mb: 64
```

For persistent high-volume namespaces, also enable the `drop` stage in `pipelineStages` for debug-level lines instead of raising the ceiling indefinitely.

**Labels missing — pod/namespace variables in Grafana dashboard are empty**

Verify that Promtail's Kubernetes relabelling is intact:

```bash
kubectl get configmap -n monitoring loki-promtail -o yaml
```

Look for `__meta_kubernetes_namespace` and `__meta_kubernetes_pod_name` relabel rules. If absent, remove any `config.file` override from `values.yaml` and let the chart generate the default scrape config.