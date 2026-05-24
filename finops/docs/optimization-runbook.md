# FinOps Optimization Runbook

> Decision guide for closing the loop from alert to implemented optimization change.

---

## Trigger Conditions

Use this runbook when any of these occur:

- Budget alert fires in [finops/prometheus/budget-alerts.yaml](../prometheus/budget-alerts.yaml): `ComplianceScoreWarning`, `BudgetThreshold80`, or `BudgetThreshold100`
- Cost anomaly alert fires in [finops/prometheus/anomaly-alerts.yaml](../prometheus/anomaly-alerts.yaml): `CostAnomalyDetected`
- Monthly report shows month-over-month increase > 15%
- VPA recommendations are open for > 30 days

---

## Decision Tree

```
FinOps alert fires
│
├── Budget alert (BudgetThreshold80 or BudgetThreshold100)?
│   ├── New workload deployed this month?
│   │   ├── YES → Check if workload is over-provisioned → Section 2: Resource Rightsizing
│   │   └── NO → Investigate cost anomaly → Section 3: Anomaly Investigation
│   └── Reserved capacity opportunity identified?
│       └── YES → Section 4: Reserved Capacity Commitment
│
├── Cost anomaly (CostAnomalyDetected)?
│   ├── New namespace or workload?
│   │   └── YES → Check for missing cost labels → Section 1: Label Compliance
│   └── Existing workload spiked?
│       └── YES → Check for runaway HPA scaling → Section 3: Anomaly Investigation
│
└── Monthly report shows MoM increase?
    └── YES → Run normalize-cloud-costs.py → identify largest movers → Section 2 or 4
```

---

## Section 1: Label Compliance

Identify unlabeled resources:

```bash
python finops/scripts/validate-cost-tags.py --all-namespaces --output json | jq '.violations[]'
```

Fix path:

1. Add required labels in deployment manifests:
   - `finops.org/costcenter`
   - `finops.org/environment`
2. Re-deploy workload.
3. Verify update appears in Kubecost within 1 hour.

References:

- [finops/docs/cost-tagging-schema.md](cost-tagging-schema.md)
- [finops/policies/enforce-resource-limits.yaml](../policies/enforce-resource-limits.yaml)

---

## Section 2: Resource Rightsizing

1. Identify candidates:

```bash
python finops/scripts/analyze-rightsizing.py --namespace <ns> --savings-threshold 20
```

2. Verify VPA has enough data (minimum 24h):

```bash
kubectl get vpa -n <ns>
```

3. Generate optimization PR artifacts:

```bash
python finops/scripts/generate-optimization-pr.py --namespace <ns>
```

4. Review generated patch files and confirm no safety warnings.
5. Test staging first:

```bash
kubectl apply -k optimization-patches/<ns>/
```

6. Monitor for 24h:
   - OOMKilled pods
   - Latency increase
   - Error rate increase
7. If stable, open PR with generated `optimization-patches/PR-DESCRIPTION.md`.

---

## Section 3: Anomaly Investigation

1. Identify which cost center spiked:

```bash
python finops/scripts/normalize-cloud-costs.py --by team --period 7
```

2. Identify workload contributor in Kubecost/OpenCost dashboard:
   - [finops/docs/runbooks/investigate-cost-spike.md](runbooks/investigate-cost-spike.md)
3. Check HPA scale events:

```bash
kubectl get events -n <ns> --field-selector reason=SuccessfulRescale
```

4. Check for runaway jobs:

```bash
kubectl get jobs -A --sort-by=.metadata.creationTimestamp
```

5. If runaway job confirmed:

```bash
kubectl delete job <name> -n <ns>
```

Then investigate root cause before re-enabling.

---

## Section 4: Reserved Capacity Commitment

1. Run advisor:

```bash
python finops/scripts/reserved-capacity-advisor.py --min-savings 500 --max-risk medium
```

2. Review proposal and verify workload stability >= 3 months.
3. Commitments greater than $10,000/year require leadership approval. # <-- CHANGE THIS: Replace with your policy threshold; valid values are annual USD limits such as 5000, 10000, 25000; source from your finance governance policy.
4. Execute commitment through cloud console or Terraform modules:
   - [terraform/aws-eks](../../terraform/aws-eks)
   - [terraform/azure-aks](../../terraform/azure-aks)
   - [terraform/gcp-gke](../../terraform/gcp-gke)
5. Update [finops/config/budgets.yaml](../config/budgets.yaml) with committed-rate impact.
