# FinOps Troubleshooting Guide

> **Audience**: Platform team
> **Purpose**: Diagnose and resolve common FinOps component failures

---

## 1. Cost Monitoring (Kubecost / OpenCost)

### Problem: Kubecost UI is not accessible

**Symptoms**: Ingress returns 404 or 502; `curl kubecost.finops.svc.cluster.local:9090/healthz` fails.

**Diagnosis**:
```bash
# Check pod status
kubectl get pods -n finops -l app=kubecost

# Check pod logs
kubectl logs -n finops -l app=kubecost --tail=50

# Check Ingress
kubectl describe ingress -n finops kubecost
```

**Common causes and fixes**:
- Pod in CrashLoopBackOff → check resource limits, increase memory if OOMKilled
- Ingress class not set → add `kubernetes.io/ingress.class: nginx` annotation
- TLS secret missing → create TLS secret or disable TLS in Helm values

---

### Problem: Cost data is stale (> 6 hours old)

**Alert**: `CostMonitoringDataStale`

**Diagnosis**:
```bash
# Check Kubecost diagnostics
curl http://kubecost.finops.svc.cluster.local:9090/diagnostics

# Check cloud provider API connectivity
kubectl logs -n finops -l app=kubecost -c cost-model | grep -i "cloud\|billing\|error" | tail -20
```

**Common causes**:
- Cloud provider API credentials expired → rotate IAM role/service principal
- IRSA/Workload Identity not configured → verify pod annotations and IAM trust policy
- Cloud billing API quota exceeded → request quota increase

---

### Problem: No cost data for a namespace

**Symptoms**: Namespace exists but shows $0 in Kubecost

**Diagnosis**:
```bash
# Verify namespace labels (Kubecost uses labels for aggregation)
kubectl get namespace <ns> -o jsonpath='{.metadata.labels}'

# Check if Prometheus is scraping the namespace
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'kube_pod_info{namespace="<ns>"}'
```

**Fix**: Ensure Prometheus is scraping all namespaces. Check `prometheus.serviceMonitorNamespaceSelector` in Helm values.

---

## 2. VPA Recommendations

### Problem: VPA shows no recommendations

**Symptoms**: VPA object exists but `status.recommendation` is empty.

**Diagnosis**:
```bash
kubectl describe vpa <name> -n <namespace>
kubectl logs -n kube-system -l app=vpa-recommender --tail=50
```

**Common causes**:
- Insufficient data: VPA needs 24–48 hours minimum. **Wait and retry.**
- Metrics Server not installed: `kubectl top pods` would also fail
- VPA version incompatibility with Kubernetes version

---

### Problem: VPA recommends very high or very low resources

**Cause**: Short data window or unusual workload burst at sampling time.

**Fix**: Check the VPA's `status.recommendation.containerRecommendations.target` vs the `upperBound` and `lowerBound`. Use the `target` value — it represents the steady-state recommendation.

---

## 3. Kyverno Policies

### Problem: Pods are blocked by the `require-cost-labels` policy

**Symptoms**: `kubectl apply` returns admission webhook error.

**Diagnosis**:
```bash
# Check exact error message
kubectl apply -f my-pod.yaml 2>&1

# List Kyverno policies
kubectl get clusterpolicies -l finops.org/policy-id

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=30
```

**Fix**: Add the required labels to your pod template spec:
```yaml
metadata:
  labels:
    finops.org/costcenter: "engineering"
    finops.org/environment: "production"
```

---

### Problem: Kyverno webhook is blocking ALL pod creation (incident)

**Symptoms**: Nothing can be deployed; all pods fail with webhook timeout.

**Emergency remediation**:
```bash
# Option 1: Set policy to Audit mode (non-blocking)
./finops/scripts/deploy-policies.sh --audit-mode

# Option 2: Delete Kyverno webhook temporarily (escalate to platform team)
kubectl delete mutatingwebhookconfigurations kyverno-resource-mutating-webhook-cfg
kubectl delete validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg
```

Restore after incident investigation.

---

## 4. Budget Alerting

### Problem: Budget alerts are not firing

**Diagnosis**:
```bash
# Check if alerting rules are loaded in Prometheus
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'ALERTS{alertname=~"BudgetThreshold.*"}'

# Verify PrometheusRule is loaded
kubectl get prometheusrule -n monitoring finops-budget-alerts

# Check rule evaluation errors
kubectl exec -n monitoring deploy/prometheus -- \
  promtool rules test --rules-files /etc/prometheus/rules/*.yaml
```

**Common causes**:
- Missing `finops_budget_current_spend` metric → Kubecost custom metrics exporter not running
- `PrometheusRule` label doesn't match Prometheus selector → check `release:` label

---

### Problem: Alerts fire but Slack notifications are not received

**Diagnosis**:
```bash
# Check Alertmanager logs
kubectl logs -n monitoring -l app=alertmanager --tail=30

# Test Slack webhook manually
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "FinOps test notification"}'
```

**Common cause**: Webhook URL is expired or rotated. Update the Alertmanager secret.

---

## 5. Infracost CI/CD Integration

### Problem: Infracost step fails with API key error

```
Error: Invalid API key
```

**Fix**: Verify `INFRACOST_API_KEY` is set in the CI/CD secrets and is a valid key from [infracost.io](https://www.infracost.io/docs/#2-get-api-key).

---

### Problem: Infracost cannot estimate a Terraform resource

```
Infracost: the following resources are not supported
```

**This is not a blocking failure** — the PR check is marked as a warning (not failure). The cost estimate will be partial. Document the unsupported resource and track manually.

---

### Problem: Cost threshold fails on every PR despite no real changes

**Cause**: Terraform provider version bump changed resource pricing format.

**Fix**: Update the Infracost base file or adjust the threshold in `.infracost.yml`.

---

## 6. Cost Reports

### Problem: Monthly cost report CronJob fails

**Diagnosis**:
```bash
# Check CronJob history
kubectl get jobs -n finops -l app.kubernetes.io/name=cost-report-cronjob

# Check failed job logs
kubectl logs -n finops job/<job-name>
```

**Common causes**:
- `REPORT_BUCKET` secret not set → add `finops-export-credentials` secret
- IAM permission denied → verify IRSA/Workload Identity has `s3:PutObject` permission
- Kubecost API timeout → increase `activeDeadlineSeconds` in CronJob spec

---

## 7. Grafana Dashboards

### Problem: Dashboards show "No data"

**Diagnosis**:
```bash
# Verify Prometheus has the expected metrics
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'kubecost_namespace_cost_hourly'

# Check Grafana data source
curl http://grafana.monitoring.svc.cluster.local:3000/api/datasources \
  -H "Authorization: Bearer $GRAFANA_API_KEY"
```

**Common causes**:
- Prometheus data source URL wrong in Grafana → verify `prometheus.url` in Grafana Helm values
- Kubecost metrics not exposed → check Kubecost ServiceMonitor

---

## Getting Help

- **FinOps Slack channel**: `#platform-finops`
- **Escalation**: Platform team on-call (PagerDuty)
- **GitHub Issues**: Tag with `finops` label
