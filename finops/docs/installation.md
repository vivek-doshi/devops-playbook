# FinOps — Installation Guide

> **Prerequisites**: Prometheus + Grafana (kube-prometheus-stack), Kyverno, kubectl access
> **Time**: 60–90 minutes for full deployment

---

## Prerequisites

Ensure these are already installed before proceeding:

| Component | Version | Check |
|-----------|---------|-------|
| Kubernetes | 1.25+ | `kubectl version` |
| Helm | 3.12+ | `helm version` |
| kube-prometheus-stack | 45+ | `kubectl get pods -n monitoring` |
| Kyverno | 1.10+ | `kubectl get clusterpolicies` |
| kubectl | 1.25+ | `kubectl version --client` |

```bash
# Run the environment checker
bash scripts/env-checker.sh
```

---

## Step 1 — Create the finops namespace

```bash
kubectl create namespace finops --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace finops \
  finops.org/costcenter=platform-infra \
  finops.org/environment=production
```

---

## Step 2 — Deploy cost monitoring (Kubecost or OpenCost)

Choose one tool. For guidance, see [`finops/docs/kubecost-vs-opencost.md`](kubecost-vs-opencost.md).

```bash
# Deploy Kubecost
./finops/scripts/install-cost-monitoring.sh --tool kubecost

# OR deploy OpenCost
./finops/scripts/install-cost-monitoring.sh --tool opencost
```

Verify:
```bash
kubectl rollout status deployment -n finops -l app=kubecost
kubectl port-forward svc/kubecost-cost-analyzer -n finops 9090:9090
# Open: http://localhost:9090
```

Configure cloud provider integrations: [`finops/docs/cloud-provider-setup.md`](cloud-provider-setup.md)

---

## Step 3 — Deploy VPA (recommendation mode)

```bash
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm repo update

helm upgrade --install vpa fairwinds-stable/vpa \
  --namespace kube-system \
  --values finops/helm/vpa-values.yaml \
  --wait
```

Verify:
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=vpa
```

---

## Step 4 — Deploy Kyverno cost governance policies

```bash
# First, test in audit mode (non-blocking)
./finops/scripts/deploy-policies.sh --audit-mode

# Verify no unexpected denials in Kyverno logs for 24 hours, then enforce
./finops/scripts/deploy-policies.sh

# Verify
kubectl get clusterpolicies -l finops.org/policy-id
```

---

## Step 5 — Deploy Prometheus alerting rules

```bash
# Budget alerts
kubectl apply -f finops/prometheus/budget-alerts.yaml -n monitoring

# Anomaly detection
kubectl apply -f finops/prometheus/anomaly-alerts.yaml -n monitoring

# Tag compliance
kubectl apply -f finops/prometheus/tag-compliance-alerts.yaml -n monitoring

# Verify rules are loaded
kubectl get prometheusrule -n monitoring -l finops.org/component
```

---

## Step 6 — Configure budget thresholds

Edit [`finops/config/budgets.yaml`](../config/budgets.yaml) to add your cost centers, then:

```bash
./finops/scripts/deploy-budget-alerts.sh --config finops/config/budgets.yaml
```

---

## Step 7 — Configure Alertmanager

Update secrets for Slack/PagerDuty webhooks, then apply:

```bash
# Create secrets
kubectl create secret generic alertmanager-finops-credentials \
  --from-literal=SLACK_WEBHOOK_URL_FINOPS=https://hooks.slack.com/... \
  --from-literal=SLACK_WEBHOOK_URL_PLATFORM=https://hooks.slack.com/... \
  --from-literal=PAGERDUTY_INTEGRATION_KEY_PLATFORM=... \
  -n monitoring

# Apply Alertmanager config
kubectl apply -f finops/prometheus/alertmanager-budget-config.yaml -n monitoring
```

---

## Step 8 — Deploy Grafana dashboards

```bash
export GRAFANA_API_KEY="your-api-key"
export GRAFANA_URL="http://grafana.monitoring.svc.cluster.local:3000"

./finops/scripts/deploy-dashboards.sh \
  --grafana-url "$GRAFANA_URL" \
  --api-key "$GRAFANA_API_KEY"
```

Verify all dashboards appear in Grafana under the **FinOps** folder.

---

## Step 9 — Deploy the monthly cost report CronJob

```bash
# Create export credentials secret (for S3/Blob/GCS)
kubectl create secret generic finops-export-credentials \
  --from-literal=report_bucket=my-finops-reports \
  -n finops

# Create cluster config
kubectl create configmap finops-config \
  --from-literal=cluster_name=production \
  --from-literal=cloud_provider=aws \
  -n finops

# Deploy CronJob
kubectl apply -f finops/kubernetes/cost-report-cronjob.yaml
```

---

## Step 10 — Infracost CI/CD integration

For each repository with Terraform:

1. Copy [`finops/infracost/.infracost.yml`](../infracost/.infracost.yml) to the repo root
2. Add `INFRACOST_API_KEY` to CI/CD secrets
3. Copy the appropriate CI template:
   - GitHub Actions: `finops/cicd/github-actions-infracost.yml` → `.github/workflows/infracost.yml`
   - Azure Pipelines: include `finops/cicd/azure-pipelines-infracost.yml`
   - GitLab CI: include `finops/cicd/gitlab-ci-infracost.yml`

---

## Step 11 — Verify the full installation

```bash
# Tag compliance
python finops/scripts/validate-cost-tags.py --all-namespaces

# Rightsizing report
python finops/scripts/analyze-rightsizing.py --all-namespaces

# Test budget metric
kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant 'ALERTS{alertname=~".*Budget.*"}'

# Check all dashboards
curl -s http://grafana.monitoring.svc.cluster.local:3000/api/dashboards/home \
  -H "Authorization: Bearer $GRAFANA_API_KEY" | jq '.dashboards[] | .title'
```

Congratulations — the FinOps system is now fully operational. 🎉

---

## Next Steps

- Read the [FinOps Workflow Guide](finops-workflow.md) to understand when to perform FinOps reviews
- Onboard your first team using [onboard-new-team.md](runbooks/onboard-new-team.md)
- Run the rightsizing analyzer to find quick wins: `python finops/scripts/analyze-rightsizing.py --all-namespaces`
