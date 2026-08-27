# FinOps — Infracost Integration Guide

> This guide explains how to set up Infracost in your CI/CD pipelines to get cost estimates on every Terraform PR.

---

## What is Infracost?

Infracost calculates the monthly cost impact of Terraform changes and posts a breakdown as a PR comment. This enables developers to see the cost impact of their changes before they are merged.

Example PR comment:
```
FinOps Cost Estimate
Monthly cost change: +$127.40 (+8.5%)

+ aws_db_instance.main           +$87.60/month
+ aws_s3_bucket.data             +$15.00/month
+ aws_cloudwatch_log_group.app   +$24.80/month
```

---

## Setup

### 1. Get an Infracost API key

```bash
# Install CLI
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Register for a free API key
infracost auth login
```

Copy your API key from https://dashboard.infracost.io

### 2. Add API key to CI/CD secrets

**GitHub Actions**:
```
Repository Settings → Secrets and variables → Actions → New repository secret
Name: INFRACOST_API_KEY
Value: <your key>
```

**Azure Pipelines**:
```
Pipeline → Edit → Variables → New variable
Name: INFRACOST_API_KEY
Value: <your key>
Mark as secret: ✅
```

**GitLab CI**:
```
Settings → CI/CD → Variables → Add variable
Key: INFRACOST_API_KEY
Value: <your key>
Protected: ✅ | Masked: ✅
```

### 3. Add CI/CD template

Copy the appropriate template from `finops/cicd/`:

```bash
# GitHub Actions
cp finops/cicd/github-actions-infracost.yml .github/workflows/infracost.yml

# GitLab CI — add to .gitlab-ci.yml:
# include:
#   - project: your-org/cicd-reference
#     file: finops/cicd/gitlab-ci-infracost.yml

# Azure Pipelines — include in azure-pipelines.yml:
# extends:
#   template: finops/cicd/azure-pipelines-infracost.yml@cicd-reference
```

### 4. Add Infracost config to your repo

```bash
cp finops/infracost/.infracost.yml ./
# Edit .infracost.yml to set your TF_ROOT path and thresholds
```

---

## Configuration

### `.infracost.yml` options

```yaml
version: 0.1

projects:
  - path: terraform/        # Path to Terraform root module
    name: prod-infra        # Friendly name for reporting

cost_thresholds:
  percentage_increase: 20   # Block PR if > 20% cost increase
  absolute_increase_usd: 500 # Block PR if > $500/month increase

currency: USD
```

### Adjusting thresholds per repository

Different repositories may have different risk tolerance. Override thresholds in `.infracost.yml`:

| Team type | Suggested percentage | Suggested absolute |
|-----------|---------------------|-------------------|
| Feature teams | 20% | $500/month |
| Platform/infra teams | 30% | $2000/month |
| ML/data teams | 50% | $5000/month |
| Experimental repos | 100% (no gate) | No limit |

### Usage files

For resources where Infracost cannot infer usage (e.g., data transfer, Lambda invocations), provide estimated usage:

```yaml
# infracost-usage.yml
version: 0.1
resource_usage:
  aws_lambda_function.my_function:
    monthly_requests: 1000000
    request_duration_ms: 250
  aws_s3_bucket.data:
    storage_gb: 100
    monthly_put_requests: 10000
    monthly_get_requests: 50000
```

Reference in `.infracost.yml`:
```yaml
projects:
  - path: terraform/
    usage_file: infracost-usage.yml
```

---

## How thresholds work

The CI pipeline calculates:

1. **Baseline cost** — monthly cost of the current `main` branch
2. **New cost** — monthly cost with the PR's changes
3. **Difference** — `New cost - Baseline cost`
4. **Percentage increase** — `Difference / Baseline * 100`

If either threshold is exceeded, the CI job fails and requires resolution before merge.

### Requesting a threshold exception

If you have a legitimate reason to exceed the threshold:

1. Document the business justification in the PR description
2. Tag `#finops-requests` in Slack with a link to the PR
3. The FinOps team will review and either:
   - Approve by adjusting the threshold in the workflow for that PR
   - Request changes to reduce the cost impact
   - Approve with conditions (e.g., scheduled cleanup)

---

## Troubleshooting

### "API key invalid"
Verify your `INFRACOST_API_KEY` secret is set correctly. API keys are available at https://dashboard.infracost.io

### "Resource not supported"
Infracost does not support all Terraform resources. The CI job treats unsupported resources as warnings, not failures. The cost estimate will be partial.

### "Baseline cost calculation failed"
Ensure the CI runner has access to the target branch. For GitHub Actions, verify the `actions/checkout` step uses `fetch-depth: 0`.

### Threshold fires on every PR despite no changes
Check if Terraform state drift or provider version bumps are causing apparent changes. Consider adding `--terraform-force-cli=false` to Infracost arguments.

---

## Reference

- [Infracost Docs](https://www.infracost.io/docs/)
- [Supported resources](https://www.infracost.io/docs/supported_resources/)
- [CI/CD integrations](https://www.infracost.io/docs/integrations/)
