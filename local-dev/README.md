# Local Kubernetes

Use the Kind tooling in [kind/setup.sh](kind/setup.sh) when you want a disposable local cluster for testing both the Kustomize overlay in [../cd/kubernetes/_overlays/dev/kustomization.yaml](../cd/kubernetes/_overlays/dev/kustomization.yaml) and the Helm chart in [../cd/helm/webapp](../cd/helm/webapp) before pushing changes upstream.

## Prerequisites

- Kind: https://kind.sigs.k8s.io/
- kubectl: https://kubernetes.io/docs/tasks/tools/
- Helm: https://helm.sh/docs/intro/install/
- Docker Desktop or another Docker-compatible engine with Kubernetes-friendly resource limits

If you use the repository devcontainer, `stern` is already installed there and works well for local pod log tailing.

## Quick Start

```bash
bash local-dev/kind/setup.sh
kubectl get pods -A
bash local-dev/kind/load-image.sh my-app:dev-latest path/to/Dockerfile
```

The setup script brings up a three-node Kind cluster, a local registry on `localhost:5001`, the repo's dev Kustomize overlay, and the Helm chart smoke-test deployment.

## Test a Helm Chart Change

1. Update files under [../cd/helm/webapp](../cd/helm/webapp).
2. Re-run `bash local-dev/kind/setup.sh` to apply the chart again idempotently.
3. Open `http://localhost/helm` to confirm ingress routing still works.
4. Tail chart logs with `stern webapp -n webapp` if the rollout stalls.

## Test a Kustomize Overlay Change

1. Update files under [../cd/kubernetes/_base](../cd/kubernetes/_base) or [../cd/kubernetes/_overlays/dev](../cd/kubernetes/_overlays/dev).
2. Re-run `kubectl apply -k cd/kubernetes/_overlays/dev/` or just re-run `bash local-dev/kind/setup.sh`.
3. Open `http://localhost/` to test the overlay-backed ingress.
4. Tail overlay logs with `stern app -n dev` to inspect readiness and liveness behaviour.

## Browser Access

- Kustomize overlay: `http://localhost/`
- Helm chart: `http://localhost/helm`

## Common Issues

### Docker Desktop or WSL2 does not have enough resources

This setup expects roughly 6 CPUs and 12 GiB available for three Kind nodes at 2 CPU / 4 GiB each. Increase Docker Desktop or WSL2 memory and CPU allocations if node startup or ingress rollout is slow.

### Ports 80 or 443 are already in use

Stop the conflicting process or change the `hostPort` mappings in [kind/kind-config.yaml](kind/kind-config.yaml) before rerunning setup. Web servers, VPN clients, and other local Kubernetes clusters are the usual conflicts.

### Image pull failures

Run `docker ps` to confirm the `kind-registry` container is running, then push or load your image again with [kind/load-image.sh](kind/load-image.sh). The Kind config maps `localhost:5001` to the in-network registry container, so local pushes should be enough once the registry is healthy.

## Comparison

| Option | Best when | Tradeoffs |
|---|---|---|
| Kind | You want reproducible CI-like clusters, fast rebuilds, and GitOps-friendly manifest testing | Requires Docker resources and some registry wiring |
| Minikube | You want a more feature-rich single-node local Kubernetes with built-in addons | Heavier footprint and less close to multi-node production topologies |
| Docker Desktop Kubernetes | You want the quickest one-node cluster with minimal extra tooling | Less portable across teams and weaker parity with scripted CI environments |
