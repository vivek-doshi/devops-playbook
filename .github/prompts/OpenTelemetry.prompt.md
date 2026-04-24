---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate OpenTelemetry collector configuration as a Kubernetes sidecar and environment variable templates for instrumented applications.'
---

# OpenTelemetry Configuration Generator

You are a senior observability engineer. Generate OpenTelemetry collector configuration that applications in this repo can use to emit traces, metrics, and logs to a backend.

## Context

Read these files first:
- `cd/kubernetes/_base/deployment.yaml` — you will add the OTel sidecar to this pattern
- `docker/dotnet/Dockerfile.api` — .NET apps will use auto-instrumentation
- `docker/python/Dockerfile.fastapi` — Python apps will use opentelemetry-sdk
- `docker/java/Dockerfile.springboot` — Java apps will use the OTel Java agent
- `cd/helm/webapp/values.yaml` — understand how to expose sidecar configuration via Helm values

## Your deliverables

### 1. `observability/opentelemetry/collector-sidecar.yaml`

A Kubernetes patch file (strategic merge patch) that adds an OTel collector sidecar to any Deployment. The sidecar:
- Uses `otel/opentelemetry-collector-contrib:0.91.0` — add a comment to check for updates quarterly
- Mounts a ConfigMap containing the collector config (see item 2)
- Exposes ports:
  - 4317: OTLP gRPC receiver (for apps sending traces)
  - 4318: OTLP HTTP receiver
  - 8888: Prometheus metrics about the collector itself
- Sets resource requests: 100m CPU, 128Mi memory; limits: 500m CPU, 512Mi memory
- Includes a readiness probe on port 13133 (`/`)
- Adds the comment: `# Add this sidecar to any Deployment that needs distributed tracing`

### 2. `observability/opentelemetry/collector-config.yaml`

A ConfigMap containing the OTel collector configuration with:

**Receivers:**
- `otlp` with both grpc (4317) and http (4318) endpoints
- `prometheus` self-scrape on 8888

**Processors:**
- `batch` with 5 second timeout and 1000 item max — add comment explaining why batching matters for performance
- `memory_limiter` set to 80% of the sidecar memory limit
- `resource` to add `k8s.cluster.name`, `k8s.namespace.name`, `k8s.pod.name` attributes from environment variables
- `filter/exclude_health` to drop traces from `/health` and `/health/ready` endpoints — add comment explaining this reduces noise

**Exporters:**
- `otlp/tempo` pointing to a Tempo instance — use `${TEMPO_ENDPOINT}` env var with a `# <-- CHANGE THIS` comment
- `prometheusremotewrite` for metrics to Prometheus — use `${PROMETHEUS_REMOTE_WRITE_URL}` env var
- `debug` exporter disabled by default (set `verbosity: basic`) — add comment explaining how to enable for troubleshooting

**Pipelines:**
- `traces`: receivers[otlp] → processors[memory_limiter, resource, filter/exclude_health, batch] → exporters[otlp/tempo]
- `metrics`: receivers[otlp, prometheus] → processors[memory_limiter, batch] → exporters[prometheusremotewrite]

### 3. `observability/opentelemetry/env-vars/dotnet.env`

Environment variable template for .NET applications:
OpenTelemetry auto-instrumentation for .NET
Add these to your Deployment env section or Helm values
OTEL_SERVICE_NAME=<your-service-name>          # <-- CHANGE THIS
OTEL_SERVICE_VERSION=<your-version>            # <-- CHANGE THIS
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.1                    # 10% sampling in production
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=$(ASPNETCORE_ENVIRONMENT)
OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES=*
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp

Add a comment block at the top explaining how to add the OTel .NET NuGet packages.

### 4. `observability/opentelemetry/env-vars/python.env`

Environment variable template for Python/FastAPI applications with equivalent settings and a comment block explaining `pip install opentelemetry-distro opentelemetry-exporter-otlp` and the `opentelemetry-instrument` wrapper command.

### 5. `observability/opentelemetry/env-vars/java.env`

Environment variable template for Java/Spring Boot with equivalent settings and a comment block explaining how to add the Java agent JAR to the Docker image and the `-javaagent` JVM argument.

### 6. `observability/opentelemetry/README.md`

A guide covering:
- The three signals: traces, metrics, logs — one paragraph each explaining what they add
- How to add the sidecar to a Deployment (kubectl patch command)
- How to instrument each language (link to env var files)
- How to verify traces are flowing: `kubectl logs <pod> -c otel-collector`
- Sampling strategy explanation: why 10% in production and 100% in dev
- How to add the Tempo datasource to Grafana for trace viewing
- A diagram (ASCII) showing: App → OTel Sidecar → Tempo/Prometheus

## Style rules

- All YAML comments must explain the "why", not just the "what"
- Sampling rates must have comments explaining the production vs development tradeoff
- The sidecar resource limits must have comments explaining the sizing rationale
- Environment variable files must be valid shell syntax (usable with `env_file:` in Docker Compose and `envFrom` in Kubernetes)
- Pin the collector image version and add a comment about quarterly update cadence