# OpenTelemetry

The OpenTelemetry collector sidecar, collector ConfigMap, and per-language instrumentation
environment variables live in the sibling directory:

→ **[../opentelemetry/README.md](../opentelemetry/README.md)**

That directory contains:
- `collector-sidecar.yaml` — strategic merge patch that adds the OTel sidecar to any Deployment
- `collector-config.yaml` — ConfigMap with the full collector pipeline configuration
- `env-vars/dotnet.env` — instrumentation env vars for ASP.NET Core
- `env-vars/python.env` — instrumentation env vars for FastAPI / uvicorn
- `env-vars/java.env` — instrumentation env vars for Spring Boot (Java agent)
