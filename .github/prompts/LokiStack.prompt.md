---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Loki and Promtail Helm values for log aggregation from the Kubernetes workloads in this repo.'
---

# Loki Log Aggregation Stack Generator

You are a senior SRE. Generate Helm values for Loki and Promtail that aggregate logs from the Kubernetes workloads deployed by this repo.

## Context

Read these files first:
- `cd/kubernetes/_base/deployment.yaml` — understand the workload labels
- `cd/helm/webapp/values.yaml` — understand label structure
- `docker/dotnet/Dockerfile.api` — understand that .NET apps log to stdout (ASPNETCORE_ENVIRONMENT)
- `docker/python/Dockerfile.fastapi` — understand that Python apps use uvicorn structured logging
- `observability/prometheus/values.yaml` (if it exists) — ensure Grafana datasource is consistent
- `docs/guides/environment-strategy.md` — understand namespace-per-environment strategy

## Your deliverables

### 1. `observability/loki/values.yaml`

Helm values for `loki-stack` chart (or `loki` standalone chart version 5.x) that configure:

**Loki:**
- Single binary mode (monolithic) — add a comment explaining this is appropriate for clusters up to ~200GB/day; link to scalable mode docs for larger deployments
- Filesystem storage backend (for simplicity) with a `# <-- CHANGE THIS` comment pointing to S3/GCS/Azure options for production
- Retention: 30 days (matching Prometheus retention)
- Chunk encoding: `snappy`
- Ingester: configure WAL (write-ahead log) for durability
- Limits config:
  - `ingestion_rate_mb: 16`
  - `ingestion_burst_size_mb: 32`
  - `max_query_length: 721h` (30 days + 1 hour buffer)
  - `max_streams_per_user: 10000`
- Resource requests/limits for a mid-size cluster

**Promtail (DaemonSet):**
- Scrape configs for:
  - All pods (via `kubernetes_sd_configs`)
  - System logs from `/var/log/` on each node
- Pipeline stages for each detected log format:
  - JSON logs (FastAPI, structured Python): parse `time`, `level`, `message`, `trace_id` fields
  - Plain text logs (.NET, Java): extract timestamp and level via regex
  - Nginx access logs: parse into structured fields
- Label extraction: always include `namespace`, `pod`, `container`, `node` as Loki labels
- Drop debug logs in production namespaces (add a comment: reduces log volume significantly)
- Resource requests appropriate for a DaemonSet (low, as it runs on every node)

### 2. `observability/loki/grafana-datasource.yaml`

A Grafana datasource ConfigMap that:
- Adds Loki as a datasource named `Loki`
- Points to the Loki service within the cluster
- Sets the label `grafana_datasource: "1"` so the Grafana sidecar picks it up automatically (consistent with the Prometheus values)
- Adds a derived field linking `trace_id` in logs to Tempo/Jaeger traces (placeholder with `# <-- CHANGE THIS`)

### 3. `observability/loki/dashboards/log-explorer.json`

A Grafana dashboard JSON that provides:
- A variable for namespace selection (multi-value)
- A variable for pod selection (filtered by namespace)
- A log panel showing raw logs for the selected pod
- A stat panel showing log rate (lines per second) over the last hour
- A bar gauge showing log volume by severity level (error, warn, info, debug)
- A time series showing error rate over time (logs with `level=error`)
- Proper dashboard metadata: title, uid, version, tags `["loki", "logs"]`

### 4. `observability/loki/README.md`

A guide covering:
- Installation: helm command with correct repo and chart version
- How to query logs in Grafana using LogQL basics (3-4 common examples)
- How to add a new pipeline stage for a custom log format
- How to increase retention or switch to object storage (S3/GCS)
- Common issues: Promtail cannot read logs (permission issue), log rate limiting, missing labels

## Style rules

- All Helm values must have comments explaining non-obvious settings
- LogQL examples in the README must be runnable copy-paste queries, not pseudocode
- Retention and storage values must have comments explaining the sizing rationale
- The DaemonSet resource requests must be justified with a comment
- Point to the Grafana dashboard import process in the README