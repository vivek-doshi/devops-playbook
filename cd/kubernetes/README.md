# Kubernetes Manifests

Raw K8s manifests using Kustomize for environment promotion.

## Structure

- `_base/`: Base configuration applied to all environments
- `_overlays/dev|staging|prod`: Environment-specific patches
- `_patterns/`: Advanced deployment patterns (blue-green, canary)

## Usage

```bash
# Preview what will be applied
kubectl kustomize cd/kubernetes/_overlays/dev

# Apply to dev
kubectl apply -k cd/kubernetes/_overlays/dev

# Apply to prod
kubectl apply -k cd/kubernetes/_overlays/prod
```
