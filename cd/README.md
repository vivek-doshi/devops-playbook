<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Continuous Deployment Templates

Templates for deploying applications to various targets.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Structure

| Folder | Purpose |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|--------|---------|
| `kubernetes/` | Raw Kubernetes manifests with Kustomize |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `helm/` | Helm chart templates |
| `targets/` | Cloud-specific deployment pipelines (AKS, EKS, GKE, App Service, ECS, Lambda, OpenShift) |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `gitops/` | ArgoCD and Flux GitOps patterns |

## Choosing a Deployment Strategy

<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Scenario | Recommendation |
|----------|---------------|
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Full K8s control | `kubernetes/_base/` with Kustomize overlays |
| Helm-managed releases | `helm/webapp/` |
| Azure-native team | `targets/azure-aks/` |
| AWS team | `targets/aws-eks/` or `targets/aws-ecs/` |
| Serverless | `targets/aws-lambda/` |
| GitOps | `gitops/argocd/` or `gitops/flux/` |
| Red Hat OpenShift | `targets/openshift/` |
