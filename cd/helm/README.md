# Helm Chart Templates

Generic Helm chart for web applications and microservices.

## Charts

| Chart | Purpose |
|-------|---------|
| `webapp/` | Generic application chart with configurable API, frontend, and sidecar settings |

## Usage

```bash
# Install to dev
helm install my-app cd/helm/webapp -f cd/helm/webapp/values.dev.yaml

# Upgrade in prod
helm upgrade my-app cd/helm/webapp -f cd/helm/webapp/values.prod.yaml

# Dry run
helm install my-app cd/helm/webapp --dry-run --debug
```
