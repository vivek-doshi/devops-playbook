# FinOps Runbook: Onboard a New Team

> **Audience**: Platform team, FinOps practitioners  
> **Use case**: Adding a new team/cost center to the FinOps system  
> **Time required**: 30–45 minutes

---

## Overview

This runbook walks you through onboarding a new team to the FinOps system, including budget configuration, namespace labeling, Grafana access, and budget alert setup.

---

## Step 1 — Gather team information

Before starting, collect:

| Field | Value | Example |
|-------|-------|---------|
| Team name | | `payments` |
| Cost center identifier | | `payments` (lowercase, no spaces) |
| Monthly budget (USD) | | `$8,000` |
| Primary Slack channel | | `#finops-payments` |
| Alert contact email | | `payments-leads@company.com` |
| PagerDuty service (optional) | | `payments-oncall` |
| Kubernetes namespace(s) | | `team-payments`, `team-payments-staging` |

---

## Step 2 — Add budget configuration

Edit [`finops/config/budgets.yaml`](../../config/budgets.yaml) to add the new cost center:

```yaml
budgets:
  # ... existing entries ...
  - cost_center: "payments"
    display_name: "Payments Team"
    monthly_threshold_usd: 8000
    alert_channels:
      slack: "#finops-payments"
      email: "payments-leads@company.com"
    namespaces:
      - "team-payments"
      - "team-payments-staging"
    thresholds:
      warning: 80
      critical: 100
      emergency: 120
```

Submit this as a PR. After merge, deploy the updated budget alerts:

```bash
./finops/scripts/deploy-budget-alerts.sh --config finops/config/budgets.yaml
```

---

## Step 3 — Label existing namespaces

If the team's namespace(s) already exist, add the required labels:

```bash
kubectl label namespace team-payments \
  finops.org/costcenter=payments \
  finops.org/environment=production

kubectl label namespace team-payments-staging \
  finops.org/costcenter=payments \
  finops.org/environment=staging
```

Verify:
```bash
kubectl get namespace team-payments -o jsonpath='{.metadata.labels}' | jq .
```

---

## Step 4 — Label existing workloads

For any existing Deployments/StatefulSets in the namespace, patch them to add labels:

```bash
# List all deployments missing finops.org labels
kubectl get deployments -n team-payments -o json | \
  jq '.items[] | select(.spec.template.metadata.labels."finops.org/costcenter" == null) | .metadata.name'

# Patch a deployment to add labels
kubectl patch deployment <name> -n team-payments \
  --type=json \
  -p='[
    {"op":"add","path":"/spec/template/metadata/labels/finops.org~1costcenter","value":"payments"},
    {"op":"add","path":"/spec/template/metadata/labels/finops.org~1environment","value":"production"}
  ]'
```

Verify tag compliance:
```bash
python finops/scripts/validate-cost-tags.py --namespace team-payments
```

---

## Step 5 — Verify cost data appears

After labeling, allow 5–15 minutes for Kubecost to collect and aggregate costs.

```bash
# Check Kubecost API for namespace data
curl "http://kubecost.finops.svc.cluster.local:9090/model/allocation?window=24h&aggregate=namespace" | \
  jq '.data[0]["team-payments"]'
```

Also verify in the [Cost Overview Grafana dashboard](https://grafana.internal.company.com/d/finops-cost-overview):
1. Set the **Namespace** filter to `team-payments`
2. Confirm cost data is visible
3. Set the **Cost Center** filter to `payments` and verify costs aggregate correctly

---

## Step 6 — Configure Grafana access

Grant the team access to FinOps dashboards in Grafana:

1. Navigate to Grafana → **Configuration → Teams**
2. Create a team for `payments` (if not existing)
3. Add team members
4. Assign **Viewer** role on the `FinOps` dashboard folder

Or via Grafana API:
```bash
curl -X POST http://grafana.monitoring.svc.cluster.local:3000/api/teams \
  -H "Authorization: Bearer $GRAFANA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Payments FinOps", "email": "payments-leads@company.com"}'
```

---

## Step 7 — Test budget alerting

Verify budget alerts will fire for the new cost center:

```bash
# Simulate a budget metric for testing (if using pushgateway)
cat <<EOF | curl -s --data-binary @- http://prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics/job/finops-test
finops_budget_current_spend{cost_center="payments"} 7000
finops_budget_threshold{cost_center="payments"} 8000
EOF

# Wait 2 minutes, then check if the warning alert fired
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'ALERTS{alertname="BudgetThresholdWarning",cost_center="payments"}'
```

Clean up test metric after verification:
```bash
curl -X DELETE http://prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics/job/finops-test
```

---

## Step 8 — Brief the team

Share the following with the new team:

1. **Cost Tagging Guide**: [`finops/docs/cost-tagging-schema.md`](../cost-tagging-schema.md)
2. **Workflow Guide**: [`finops/docs/finops-workflow.md`](../finops-workflow.md)
3. **PR Checklist**: [`finops/templates/pr-checklist.md`](../../templates/pr-checklist.md)
4. **Grafana Dashboard**: Link to the Cost Overview dashboard filtered to their cost center
5. **Budget Amount**: Their monthly threshold and the alert channels configured

---

## Checklist Summary

- [ ] Budget entry added to `finops/config/budgets.yaml` and deployed
- [ ] Namespace(s) labeled with `finops.org/costcenter` and `finops.org/environment`
- [ ] Existing workloads labeled (or Kyverno policy will enforce on next deploy)
- [ ] Tag compliance script confirms >95% compliance
- [ ] Cost data visible in Kubecost and Grafana for the new namespace
- [ ] Grafana access granted to team members
- [ ] Budget alerting tested and confirmed working
- [ ] Team briefed on FinOps labels and PR checklist
