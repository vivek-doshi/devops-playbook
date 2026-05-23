# Golden Path - Multi-Cluster Fleet

> **An opinionated, end-to-end workflow that guides developers from idea -> production**

---

## When to use this path

- You operate 3 or more Kubernetes clusters.
- You need consistent platform component delivery and policy enforcement across clusters.
- You need fleet observability without manual per-cluster configuration.

Not the right path? See [Platform Onboarding](platform-onboarding.md) Step 11 for single-cluster ArgoCD setup, and [Kubernetes Microservice](kubernetes-microservice.md) Step 11 for deploying one application to one cluster.

---

## Scale guidance

| Cluster count | Recommended approach |
|---|---|
| 1-2 | Single-cluster ArgoCD (`cd/gitops/argocd/application.yaml`) |
| 3-10 | This path - hub-and-spoke topology |
| 10-20 | This path - hierarchical topology |
| 20+ | Contact platform team - requires custom ApplicationSet generator |

---

## Prerequisites

Run the environment checker before implementation:

```bash
bash scripts/env-checker.sh
```

Required baseline:
- ArgoCD installed in at least one management cluster.
- Cluster credentials registered in ArgoCD for all target clusters.
- Terraform cluster provisioning foundation in place (for example `terraform/aws-eks/`).

---

## Flow

```text
provision clusters (Terraform) -> configure cluster-registry.yaml
-> deploy fleet ArgoCD project -> deploy fleet-applicationset
-> platform components propagate to all clusters
-> add workload overlays to cd/fleet-overlays/
-> fleet-workload-applicationset deploys to matching clusters
-> Prometheus remote_write aggregates to central store
-> fleet-level alerts fire on any cluster
```

---

## Step 1 - Add all clusters to the registry

Update [cd/gitops/argocd/fleet/cluster-registry.yaml](../../cd/gitops/argocd/fleet/cluster-registry.yaml).

---

## Step 2 - Create the fleet ArgoCD project

Apply [cd/gitops/argocd/fleet/fleet-project.yaml](../../cd/gitops/argocd/fleet/fleet-project.yaml):

```bash
kubectl apply -f cd/gitops/argocd/fleet/fleet-project.yaml
```

---

## Step 3 - Apply the platform fleet ApplicationSet

Apply [cd/gitops/argocd/fleet/fleet-applicationset.yaml](../../cd/gitops/argocd/fleet/fleet-applicationset.yaml):

```bash
kubectl apply -f cd/gitops/argocd/fleet/fleet-applicationset.yaml
```

---

## Step 4 - Verify platform components are deploying

```bash
kubectl get applications -n argocd -l fleet.argocd.io/component
```

---

## Step 5 - Apply fleet policy propagation

Apply [policy/kyverno/fleet-policy-propagation.yaml](../../policy/kyverno/fleet-policy-propagation.yaml):

```bash
kubectl apply -f policy/kyverno/fleet-policy-propagation.yaml
```

---

## Step 6 - Check policy compliance across clusters

```bash
kubectl get policyreport -A --context <each-cluster>
```

---

## Step 7 - Configure optional fleet metrics aggregation

Review [observability/prometheus/fleet-aggregation.yaml](../../observability/prometheus/fleet-aggregation.yaml) and the remote_write comment block in [observability/prometheus/values.yaml](../../observability/prometheus/values.yaml).

---

## Step 8 - Add a workload application overlay

Create `cd/fleet-overlays/<environment>/<app-name>/kustomization.yaml` following [cd/fleet-overlays/README.md](../../cd/fleet-overlays/README.md).

---

## Step 9 - Apply the workload ApplicationSet

Apply [cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml](../../cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml):

```bash
kubectl apply -f cd/gitops/argocd/fleet/fleet-workload-applicationset.yaml
```

---

## Day-2 operations

### Add a new cluster

- Update `cluster-registry.yaml` with the new cluster entry.
- Merge the change.
- ApplicationSet detects the cluster and deploys platform components automatically.

### Remove a cluster

- Set `kyverno-enforcement: audit` in `cluster-registry.yaml` first.
- Validate no pending enforcement drift.
- Remove the cluster entry from the registry.
- ArgoCD prunes generated Applications for that cluster.

### Emergency patch all clusters

- Commit fix to shared base manifests (`policy/kyverno/`, `cd/kubernetes/_base/`, or platform chart values).
- Fleet ApplicationSets reconcile and propagate within retry/backoff windows.

### Skip one cluster during a rollout

- Add a temporary `suspend: true` on the specific generated Application resource.
- Resume after validation.

---

## Guardrails

| Rule | Enforced by |
|---|---|
| No manual `kubectl apply` to fleet clusters | ArgoCD self-heal enabled |
| Platform components identical across clusters | Single ApplicationSet source |
| No cross-cluster secret sharing | `fleet-policy-propagation.yaml` deny rule |
| Cluster registry is human-maintained, not auto-generated | Comment in `cluster-registry.yaml` |
| Fleet scale limit: 20 clusters | Comment in `fleet-applicationset.yaml` |

---

## Responsibilities

| Role | Owns |
|---|---|
| Platform team | Cluster registry, fleet ApplicationSets, AppProject scope, and Day-2 fleet operations |
| Security team | Fleet policy review, Kyverno compliance, and cross-cluster guardrails |
| Application teams | Environment overlays under `cd/fleet-overlays/` and workload rollout validation |
