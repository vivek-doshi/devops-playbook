# FinOps — Cost Tagging Schema

> **Required reading for all application teams before deploying to production.**

Cost allocation tags (labels in Kubernetes) are the foundation of accurate FinOps reporting. Without them, costs cannot be attributed to the correct team or project, making chargeback impossible and showback inaccurate.

---

## Required Labels

All Pods (and their owning controllers — Deployment, StatefulSet, DaemonSet, etc.) **must** have the following labels:

| Label | Description | Example values |
|-------|-------------|----------------|
| `finops.org/costcenter` | The business unit or team responsible for this workload's cost | `engineering`, `data-science`, `frontend`, `platform-infra` |
| `finops.org/environment` | The deployment environment | `dev`, `staging`, `production` |

### Why these are required

- **`finops.org/costcenter`** — Maps workload cost to a budget and enables chargeback to the correct business unit. Without this, the workload appears in the `untagged` cost center and skews all reports.
- **`finops.org/environment`** — Allows filtering costs by environment. Production costs should be tracked separately from development/staging to avoid inflating chargeback figures.

---

## Optional Labels

| Label | Description | Example values |
|-------|-------------|----------------|
| `finops.org/team` | Owning team name (sub-unit of cost center) | `platform`, `backend-api`, `ml-infra` |
| `finops.org/project` | Project or product identifier | `api-gateway`, `recommendation-engine` |
| `finops.org/owner` | Individual owner for contact purposes | `john.doe` |

---

## How to Apply Labels

### Deployment (recommended)

Apply labels at the **pod template** level so they propagate to all pods:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
  namespace: team-platform
  labels:
    app: my-service
    # Deployment-level labels (not propagated to pods)
    finops.org/costcenter: engineering
    finops.org/environment: production
spec:
  template:
    metadata:
      labels:
        app: my-service
        # Pod template labels — REQUIRED on every pod
        finops.org/costcenter: engineering
        finops.org/environment: production
        finops.org/team: platform
        finops.org/project: my-service
```

> ⚠️ Labels must be on **both** the Deployment metadata and the pod template spec. Kyverno validates labels on the resulting Pod — the pod template labels are what matter.

### StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: team-data
spec:
  template:
    metadata:
      labels:
        finops.org/costcenter: data-science
        finops.org/environment: production
        finops.org/team: data-engineering
```

---

## Valid Cost Center Values

Cost centers must match exactly the values defined in [`finops/config/budgets.yaml`](../config/budgets.yaml):

| Cost Center | Description | Owner |
|-------------|-------------|-------|
| `engineering` | Engineering Platform | engineering-leads@company.com |
| `data-science` | Data Science & ML | data-leads@company.com |
| `frontend` | Frontend & UX | frontend-leads@company.com |
| `platform-infra` | Shared Platform Infrastructure | platform-team@company.com |

> To add a new cost center, create a PR updating `finops/config/budgets.yaml` and notify the FinOps team.

---

## Enforcement Mechanisms

### 1. Kyverno Policy (admission-time enforcement)

The `require-cost-labels` Kyverno ClusterPolicy blocks pod creation if required labels are missing:

```
Error from server: admission webhook "validate.kyverno.svc" denied the request:
Policy: require-cost-labels | Rule: validate-costcenter-label
Pod 'my-pod' is missing required label 'finops.org/costcenter'.
```

See: [`finops/policies/require-cost-labels.yaml`](../policies/require-cost-labels.yaml)

### 2. Prometheus Alerts

The `CostTagComplianceLow` alert fires when >5% of pods cluster-wide are missing required labels.

See: [`finops/prometheus/tag-compliance-alerts.yaml`](../prometheus/tag-compliance-alerts.yaml)

### 3. Tag Compliance Dashboard

Monitor compliance in Grafana: [FinOps — Tag Compliance dashboard](https://grafana.internal.company.com/d/finops-tag-compliance)

### 4. CLI Validation Script

Run manually to check compliance:

```bash
python finops/scripts/validate-cost-tags.py --all-namespaces
python finops/scripts/validate-cost-tags.py --namespace team-a --format json
```

---

## Namespace-Level Labels

While Kyverno enforces labels on pods, it is also recommended to label namespaces. This enables cost aggregation even before pods are created:

```bash
kubectl label namespace team-platform \
  finops.org/costcenter=engineering \
  finops.org/environment=production
```

---

## Troubleshooting

**Q: My deployment was rejected with a label error. What do I do?**

Add the required labels to the pod template spec in your Deployment/StatefulSet manifest. Both `finops.org/costcenter` and `finops.org/environment` must be present.

**Q: The Kyverno policy blocks system pods in kube-system.**

The policy excludes: `kube-system`, `kube-public`, `kube-node-lease`, `cert-manager`. If you need another namespace excluded, contact the platform team.

**Q: I need to use a cost center that's not in the list.**

Submit a PR to add it to [`finops/config/budgets.yaml`](../config/budgets.yaml) and notify the FinOps team to configure the budget threshold.

**Q: My pods were deployed before the policy was enforced. Are they non-compliant?**

Yes. Run `kubectl get pods --all-namespaces -o json | python finops/scripts/validate-cost-tags.py` to identify them, then update the owning Deployment/StatefulSet to add the labels.
