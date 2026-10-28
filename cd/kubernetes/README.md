# Kubernetes Manifests

Raw K8s manifests using Kustomize for environment promotion.

## Structure

- `_base/`: Base configuration applied to all environments
  - `cert-manager/` — Canonical cert-manager namespace and ClusterIssuer package. Apply this **before** any Ingress that uses `cert-manager.io/cluster-issuer`.
- `_overlays/dev|staging|prod`: Environment-specific patches
- `_patterns/`: Advanced deployment patterns (blue-green, canary)
  - `db-migration-job.yaml` — Pre-deploy database migration Job with rollback Job. Run before `Deployment` rollout.

## Usage

```bash
# Preview what will be applied
kubectl kustomize cd/kubernetes/_overlays/dev

# Promote the overlay through Argo CD or Flux; those controllers reconcile it.
```
