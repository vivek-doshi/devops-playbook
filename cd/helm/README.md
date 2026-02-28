# Helm Chart Templates

Generic Helm charts for web applications and microservices.

## Charts

| Chart | Purpose |
|-------|---------|
| `webapp/` | Generic web application (API + frontend) |
| `microservice/` | Microservice with sidecar support |

## Usage

```bash
# Install to dev
helm install my-app cd/helm/webapp -f cd/helm/webapp/values.dev.yaml

# Upgrade in prod
helm upgrade my-app cd/helm/webapp -f cd/helm/webapp/values.prod.yaml

# Dry run
helm install my-app cd/helm/webapp --dry-run --debug
```
