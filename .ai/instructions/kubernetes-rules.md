# Kubernetes Rules

Rules for manifests and patterns under cd/kubernetes/, cd/helm/, policy/, secops/, observability/, and finops/policies/.

## Workload Safety Baseline

- Every container must define CPU and memory requests and limits.
- Every service workload must define liveness and readiness probes.
- Use non-root containers and restrictive securityContext settings by default.
- Minimize container capabilities; drop all and add only what is required.
- Define PodDisruptionBudget for critical or high-resource workloads.

## Security And Network

- Enforce namespace isolation and least-privilege RBAC.
- Use NetworkPolicy to define allowed ingress and egress paths.
- Mount secrets only when needed and prefer external secret providers.
- Avoid privileged pods, hostPath, hostPID, and hostNetwork unless explicitly justified.

## Delivery And Operations

- Prefer base plus overlay model for environment-specific differences.
- Keep Helm values and Kustomize overlays minimal and environment-scoped.
- Use progressive rollout patterns for high-risk changes where applicable.
- Ensure observability standards: logs, metrics, and alert hooks exist before production rollout.

## Repo Alignment

- Reuse patterns from cd/kubernetes/_base and cd/kubernetes/_patterns.
- Keep GitOps-compatible manifests for argocd and flux targets.
- Align guardrails with policies in policy/, security/, and finops/policies/.
