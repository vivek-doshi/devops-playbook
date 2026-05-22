# FinOps PR Review Checklist Template

Add this checklist to your GitHub PR template (.github/PULL_REQUEST_TEMPLATE.md)
or GitLab MR template (.gitlab/merge_request_templates/FinOps.md)
whenever a PR includes infrastructure changes, new workloads, or Kubernetes manifests.

Usage: Copy the checklist section below into your PR description.

## FinOps Review Checklist

> Complete this checklist for PRs that add or modify Kubernetes workloads, Terraform infrastructure, or resource requests.

### Cost Labels ✅

- [ ] All new Pods/Deployments/StatefulSets have `finops.org/costcenter` label
- [ ] All new Pods/Deployments/StatefulSets have `finops.org/environment` label (dev/staging/production)
- [ ] Labels match an existing cost center in [`finops/config/budgets.yaml`](../finops/config/budgets.yaml)

### Resource Requests ✅

- [ ] CPU and memory `requests` and `limits` are explicitly set for all containers
- [ ] Resource requests are aligned with VPA recommendations (if available)
- [ ] No container requests more than 4 CPU cores or 8Gi memory without a PodDisruptionBudget
- [ ] GPU workloads have `finops.org/gpu-approved: "true"` annotation and supporting metadata

### Infrastructure Cost (Terraform changes only) ✅

- [ ] Infracost estimate has been reviewed in this PR's CI check
- [ ] Monthly cost increase is within the configured threshold (< 20% or < $500)
- [ ] If threshold is exceeded, approval from FinOps team has been obtained
- [ ] New cloud resources have appropriate cost allocation tags (AWS tags / Azure tags / GCP labels)

### VPA Recommendations (pre-production deployment) ✅

- [ ] VPA recommendations have been checked for affected workloads
- [ ] CPU/memory requests are within 20% of VPA target recommendations
- [ ] High-priority rightsizing opportunities (> 20% savings) have been addressed or deferred with justification

### Cost Impact Documentation ✅

- [ ] Estimated monthly cost impact is documented in the PR description
- [ ] Any significant cost increases (> $100/month) have a business justification
- [ ] Temporary or experimental workloads have a defined removal date

---

**Cost Impact Summary** (fill in for significant changes):

| Resource | Type | Estimated Monthly Cost |
|----------|------|----------------------|
| example-deployment | New | $XX.XX |
| | | **Total: $XX.XX** |

**Notes** (e.g., justification for threshold exceptions, deferral of VPA recommendations):

> _Add notes here_

---

📊 [FinOps Dashboard](https://grafana.internal.company.com/d/finops-cost-overview) | 
📖 [FinOps Workflow Guide](../finops/docs/finops-workflow.md) |
🔍 [Cost Tagging Schema](../finops/docs/cost-tagging-schema.md)
