# Policy

This directory contains automated policy checks that enforce the security and operational
standards demonstrated across this repository's Kubernetes manifests and CI/CD pipelines.

Policy checks run at two distinct points in the delivery lifecycle:

---

## Kyverno — Kubernetes Admission Control (Runtime)

| | |
|---|---|
| **When it runs** | At `kubectl apply` / Helm install / GitOps sync — before any resource is persisted in the cluster |
| **What it checks** | Live Kubernetes API objects: Pods, Deployments, Namespaces, Services |
| **Mode** | Enforce (blocks), Audit (logs violations), or Warn (admits with warning) |
| **Scope** | Cluster-wide via `ClusterPolicy` admission webhook |

Kyverno is the last line of defence. It catches misconfigurations that slip through CI
(e.g. a hand-crafted `kubectl apply` bypassing the pipeline entirely) and enforces cluster-wide
baselines that cannot be expressed in a linter.

→ **[kyverno/README.md](kyverno/README.md)**

Policies in this directory enforce:
- Non-root containers and no privilege escalation (`require-non-root.yaml`)
- CPU and memory resource requests and limits (`require-resource-limits.yaml`)
- Standard labels for observability (`require-labels.yaml`)
- Read-only root filesystems (`require-readonly-filesystem.yaml`)
- No `:latest` image tags in production (`disallow-latest-tag.yaml`)
- Liveness and readiness probes on multi-replica Deployments (`require-liveness-readiness.yaml`)

---

## Conftest — Static Analysis in CI (Shift-Left)

| | |
|---|---|
| **When it runs** | In the CI pipeline, against YAML files before they are applied to any cluster |
| **What it checks** | Raw manifest files in the repository (pre-render for Helm, post-render for Kustomize) |
| **Mode** | Always blocking — a failing Conftest check fails the pipeline |
| **Scope** | Configurable per directory or file pattern; runs on the developer's laptop too |

Conftest (backed by Open Policy Agent / Rego) is the shift-left counterpart to Kyverno.
It catches the same classes of problems earlier in the loop — during a pull request rather
than at deploy time — giving developers faster feedback without touching a cluster.

Use Conftest for:
- Linting plain YAML structure before cluster admission
- Checks that require access to the full file context (e.g. ensuring a Deployment and its
  Service exist in the same file)
- Developer workstation checks (`conftest test ./manifests/`) that run without cluster access

---

## When to Use Which

| Scenario | Use |
|----------|-----|
| Block non-compliant resources in any cluster (including manual applies) | Kyverno |
| Fail a PR before a change ever reaches a cluster | Conftest |
| Enforce policy on resources created by operators or controllers | Kyverno |
| Check generated Helm/Kustomize output in CI | Conftest |
| Audit existing cluster resources for compliance | Kyverno (`background: true`) |
| Check policy on local manifests without cluster access | Conftest |

Both tools are complementary — Conftest catches problems early, Kyverno provides the
safety net for anything that slips through.
