<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Helm Chart Templates

Generic Helm charts for web applications and microservices.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Charts

| Chart | Purpose |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|-------|---------|
| `webapp/` | Generic web application (API + frontend) |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `microservice/` | Microservice with sidecar support |

## Usage

<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```bash
# Install to dev
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
helm install my-app cd/helm/webapp -f cd/helm/webapp/values.dev.yaml

# Upgrade in prod
helm upgrade my-app cd/helm/webapp -f cd/helm/webapp/values.prod.yaml

# Dry run
helm install my-app cd/helm/webapp --dry-run --debug
```
