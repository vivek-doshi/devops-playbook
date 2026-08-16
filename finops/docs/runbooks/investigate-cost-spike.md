# FinOps Runbook: Investigate a Cost Spike

> **Audience**: Platform team, FinOps practitioners
> **Trigger**: `CostAnomalySpike` or `CostAnomalyCritical` Prometheus alert, or manual observation of unexpected cost growth
> **Time to resolve**: 15–60 minutes depending on root cause

---

## Step 1 — Acknowledge and orient

1. Open the **Anomaly Detection dashboard**: [FinOps — Cost Anomaly Detection](https://grafana.internal.company.com/d/finops-anomaly-detection)
2. Identify which namespace(s) are spiking and by how much vs the 7-day baseline.
3. Check the alert annotation for the affected namespace, current cost, and percentage increase.

```bash
# Quick CLI check — current vs 7-day average by namespace
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant \
  'sum by (namespace) (kubecost_namespace_cost_hourly) - sum by (namespace) (avg_over_time(kubecost_namespace_cost_hourly[7d]))'
```

---

## Step 2 — Identify what changed

### Check recent deployments

```bash
# Pods created in the last 2 hours in the suspect namespace
kubectl get pods -n <namespace> --sort-by='.metadata.creationTimestamp' | tail -20

# Recent Events
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp' | tail -30
```

### Check resource usage

```bash
# Top CPU consumers
kubectl top pods -n <namespace> --sort-by=cpu | head -15

# Top memory consumers
kubectl top pods -n <namespace> --sort-by=memory | head -15
```

### Check for runaway horizontal scaling

```bash
kubectl get hpa -n <namespace>
kubectl describe hpa -n <namespace>
```

### Check for unexpected new workloads

```bash
# Deployments modified in last 24h
kubectl get deployments -n <namespace> -o json | \
  jq '.items[] | select(.metadata.creationTimestamp > (now - 86400 | todate)) | .metadata.name'
```

---

## Step 3 — Correlate with cost data

Open [Kubecost UI](https://kubecost.finops.svc.cluster.local:9090/overview) and:

1. Navigate to **Namespace** → select the affected namespace
2. Set time range to **last 24 hours**
3. Identify the largest cost driver: compute, storage, or network
4. Drill into the workload with the highest cost

```bash
# Query Kubecost API directly
curl "http://kubecost.finops.svc.cluster.local:9090/model/allocation?window=24h&aggregate=pod&namespace=<namespace>" | jq '.data[0] | to_entries | sort_by(-.value.totalCost) | .[0:10]'
```

---

## Step 4 — Root cause categories and remediation

### A. Runaway HPA scaling
**Signs**: Many more replicas than expected, HPA at maxReplicas
**Remediation**:
```bash
# Check HPA status
kubectl describe hpa <hpa-name> -n <namespace>
# If necessary, manually scale down
kubectl scale deployment <name> -n <namespace> --replicas=<target>
# Fix the HPA metrics source to prevent recurrence
```

### B. Accidental large resource request
**Signs**: Single pod consuming disproportionate CPU/memory
**Remediation**:
```bash
# Inspect resource requests
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].resources}'
# Edit the Deployment to correct resource requests
kubectl edit deployment <name> -n <namespace>
```

### C. GPU workload running without approval
**Signs**: `nvidia.com/gpu` limit in pod spec, no `finops.org/gpu-approved` annotation
**Remediation**:
```bash
# Find GPU pods
kubectl get pods -n <namespace> -o json | jq '.items[] | select(.spec.containers[].resources.limits."nvidia.com/gpu" != null) | .metadata.name'
# Delete if unauthorized
kubectl delete pod <gpu-pod> -n <namespace>
```

### D. Storage cost spike (PV over-provisioning or new large volume)
**Signs**: Storage cost component spike in Kubecost
**Remediation**:
```bash
# Check PVC usage
kubectl get pvc -n <namespace>
python finops/scripts/detect-unused-volumes.py
```

### E. Network egress spike
**Signs**: Network cost component spike
**Remediation**: Check for data exfiltration patterns, inspect service mesh traffic metrics, check for misconfigured data replication.

### F. New untagged workload in high-cost namespace
**Signs**: `CostTagComplianceLow` alert also firing
**Remediation**:
```bash
python finops/scripts/validate-cost-tags.py --namespace <namespace>
# Add missing labels to the Deployment/StatefulSet
```

---

## Step 5 — Implement fix and verify

1. Apply the remediation from Step 4
2. Monitor the cost metric for 30 minutes:
   ```bash
   watch -n 60 'curl -s "http://prometheus:9090/api/v1/query?query=sum(kubecost_namespace_cost_hourly{namespace=\"<ns>\"})" | jq ".data.result[0].value[1]"'
   ```
3. Verify the anomaly alert resolves in Alertmanager

---

## Step 6 — Document and prevent

1. Write up a brief post-incident note: what spiked, why, how fixed
2. Consider adding a policy or budget alert to catch this earlier next time
3. If a new workload type is the cause, update the FinOps PR checklist template

---

## Reference Queries

```promql
# Cost spike percentage vs 7d average by namespace
(sum by (namespace) (kubecost_namespace_cost_hourly)
 - sum by (namespace) (avg_over_time(kubecost_namespace_cost_hourly[7d])))
/ sum by (namespace) (avg_over_time(kubecost_namespace_cost_hourly[7d])) * 100

# Top 10 most expensive namespaces right now
topk(10, sum by (namespace) (kubecost_namespace_cost_hourly))

# Budget utilization by cost center
sum by (cost_center) (finops_budget_current_spend)
/ sum by (cost_center) (finops_budget_threshold) * 100
```
