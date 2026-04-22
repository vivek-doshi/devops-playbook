<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Kubernetes Manifests

Raw K8s manifests using Kustomize for environment promotion.

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Structure

- `_base/`: Base configuration applied to all environments
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- `_overlays/dev|staging|prod`: Environment-specific patches
- `_patterns/`: Advanced deployment patterns (blue-green, canary)

<!-- Note 4: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Usage

```bash
<!-- Note 5: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Preview what will be applied
kubectl kustomize cd/kubernetes/_overlays/dev

<!-- Note 6: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Apply to dev
kubectl apply -k cd/kubernetes/_overlays/dev

# Apply to prod
kubectl apply -k cd/kubernetes/_overlays/prod
```
