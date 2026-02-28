# Continuous Deployment Templates

Templates for deploying applications to various targets.

## Structure

| Folder | Purpose |
|--------|---------|
| `kubernetes/` | Raw Kubernetes manifests with Kustomize |
| `helm/` | Helm chart templates |
| `targets/` | Cloud-specific deployment pipelines (AKS, EKS, GKE, App Service, ECS, Lambda) |
| `gitops/` | ArgoCD and Flux GitOps patterns |

## Choosing a Deployment Strategy

| Scenario | Recommendation |
|----------|---------------|
| Full K8s control | `kubernetes/_base/` with Kustomize overlays |
| Helm-managed releases | `helm/webapp/` |
| Azure-native team | `targets/azure-aks/` |
| AWS team | `targets/aws-eks/` or `targets/aws-ecs/` |
| Serverless | `targets/aws-lambda/` |
| GitOps | `gitops/argocd/` or `gitops/flux/` |
