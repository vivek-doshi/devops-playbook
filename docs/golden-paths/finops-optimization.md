# Golden Path - FinOps Optimization

> Opinionated workflow to close the loop from cost alert to merged optimization change and verified savings.

---

## When to use this path

- Your team received a FinOps alert
- Monthly cost review shows unexpected spend growth
- You want proactive cloud cost reduction on running workloads

Not the right path?

- Need to install FinOps stack first: [finops/README.md](../../finops/README.md)

---

## Prerequisites

- Kubecost/OpenCost is deployed
- VPA recommender is deployed
- Prometheus budget and anomaly alerts are active

---

## Flow

```
receive alert or review monthly report
-> identify optimization type (rightsizing | reserved | anomaly | label compliance)
-> run analysis script -> review recommendations
-> generate optimization PR (for rightsizing) or commitment proposal (for reserved)
-> test in staging -> merge to production
-> verify savings in dashboard -> close the loop
```

---

## Step 1 - Identify the trigger

Confirm which alert fired, or which KPI changed in the monthly report.

Reference: [finops/docs/optimization-runbook.md](../../finops/docs/optimization-runbook.md)

---

## Step 2 - Run cross-cloud normalization

```bash
python finops/scripts/normalize-cloud-costs.py --by team
```

Use this output to find top movers by team and cloud before selecting an action branch.

---

## Step 3 - Run rightsizing analysis

```bash
python finops/scripts/analyze-rightsizing.py --namespace <ns>
```

Focus on candidates with highest monthly savings and low operational risk.

---

## Step 4 - Generate optimization PR assets

```bash
python finops/scripts/generate-optimization-pr.py --namespace <ns> --min-savings 20
```

Outputs:

- Kustomize patches under `optimization-patches/<ns>/`
- Pre-filled `optimization-patches/PR-DESCRIPTION.md`

---

## Step 5 - Run reserved capacity advisor (quarterly)

```bash
python finops/scripts/reserved-capacity-advisor.py --min-savings 500 --max-risk medium --term 1yr
```

Use this for stable, long-running workloads only.

---

## Step 6 - Test in staging for 24h

```bash
kubectl apply -k optimization-patches/<ns>/
```

Monitor:

- OOM kills
- Error-rate changes
- Latency regressions

---

## Step 7 - Apply optimization

Merge the PR and let rollout complete in production.

---

## Step 8 - Verify savings

Validate savings in Grafana optimization dashboards within 48 hours.

---

## Step 9 - Update budget forecast

If savings materially change forecast, update [finops/config/budgets.yaml](../../finops/config/budgets.yaml).

---

## FinOps Alert Response Guide

| Alert | Immediate action | Script to run | Expected resolution time |
|---|---|---|---|
| `BudgetThreshold80` | Identify top spender | `normalize-cloud-costs.py --by team` | 1-3 days |
| `BudgetThreshold100` | Stop non-critical deployments | `normalize-cloud-costs.py --by team` | Same day |
| `CostAnomalyDetected` | Check for runaway workloads | `detect-underutilized.py` | Hours |
| VPA recommendation > 7 days old | Generate optimization PR | `generate-optimization-pr.py` | 1-2 days |
| Unused volumes detected | Review and delete | `detect-unused-volumes.py` | 1 hour |

---

## Guardrails

| Rule | Enforced by |
|---|---|
| Never reduce memory limits > 50% in one change | `generate-optimization-pr.py` safety check |
| Never commit reserved capacity for workloads < 3 months old | `reserved-capacity-advisor.py` risk scoring |
| Test resource changes in staging for 24h before production | Step 6 in this path |
| Reserved capacity commitments > $10,000/year require leadership approval | [finops/docs/optimization-runbook.md](../../finops/docs/optimization-runbook.md) Section 4 |
| All optimization PRs must include the FinOps PR checklist | [finops/templates/pr-checklist.md](../../finops/templates/pr-checklist.md) |
