# FinOps — Reserved Capacity Recommendations Guide

> Use this guide after running `python finops/scripts/analyze-reserved-capacity.py --all-namespaces`.

---

## What is Reserved Capacity?

Cloud providers offer significant discounts (25–60%) for committing to use a specific amount of compute capacity for 1 or 3 years:

| Cloud | Product | 1-year discount | 3-year discount |
|-------|---------|-----------------|-----------------|
| AWS | Reserved Instances / Savings Plans | ~30–40% | ~50–60% |
| Azure | Azure Reservations | ~32% | ~50% |
| GCP | Committed Use Discounts | ~25% | ~45% |

---

## When to Buy Reserved Capacity

**Only buy reserved capacity for stable workloads.** A stable workload is one where CPU utilization varies by less than 10% over a 90-day period.

The `analyze-reserved-capacity.py` script identifies these automatically:

```bash
# Find stable workloads and calculate savings
python finops/scripts/analyze-reserved-capacity.py --all-namespaces --format json

# Filter to high-value candidates
python finops/scripts/analyze-reserved-capacity.py --all-namespaces | grep -A5 "annual_savings_usd"
```

---

## Recommended Process

1. **Run the analysis**: Generate a report at the end of each quarter
2. **Sort by annual savings**: Focus on the top 10 candidates
3. **Verify stability**: Confirm > 90 days of stable metrics in Grafana before committing
4. **Calculate total commitment**: Sum annual savings, verify cash flow impact
5. **Purchase via cloud console**: Buy Reserved Instances or Savings Plans
6. **Update the report**: Document purchases in your FinOps tracker

---

## Decision Matrix

| Annual savings | Workload age | Action |
|---------------|--------------|--------|
| > $1,000 | > 6 months stable | Strong buy — purchase 1-year term |
| $500–1,000 | > 6 months stable | Consider purchasing 1-year term |
| > $5,000 | > 12 months stable | Consider 3-year term for maximum savings |
| < $500 | Any | On-demand OK — not worth the commitment |
| Any | < 3 months | Wait — insufficient stability data |
| Any | Highly variable | On-demand only — reserved would be wasted |

---

## AWS-Specific: EC2 Savings Plans vs Reserved Instances

| | Savings Plans | Reserved Instances |
|-|--------------|-------------------|
| Flexibility | High (apply to any EC2) | Low (specific instance type) |
| Discount | Slightly lower | Slightly higher |
| Best for | Mixed workloads | Predictable, fixed instance types |
| Recommended | ✅ General recommendation | Only for very stable, fixed workloads |

---

## Tracking Reservations

After purchasing, update the cluster-level ConfigMap with active reservation details:

```yaml
# This is informational — Kubecost/OpenCost will auto-detect reservation discounts
# via the cloud provider billing API integration.
apiVersion: v1
kind: ConfigMap
metadata:
  name: finops-reservations
  namespace: finops
data:
  # Document active reservations for auditability
  aws_savings_plan_2025_01: |
    type: compute-savings-plan
    commitment_usd_per_hour: 2.50
    term: 1-year
    start_date: 2025-01-01
    workloads: team-backend, team-api
    expected_annual_savings: 10950
```

---

## Monitoring Reservation Utilization

After purchasing, monitor that your reservations are being fully utilized:

1. Open [Cost Breakdown dashboard](https://grafana.internal.company.com/d/finops-cost-breakdown)
2. Switch to **Multi-Cloud Comparison** dashboard and check "Reserved vs On-Demand" breakdown
3. If utilization < 80% → reservations are being wasted; investigate which workloads scaled down

For AWS: Monitor in the AWS Cost Explorer → Reservations → Utilization Report.
