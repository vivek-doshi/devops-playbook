# Golden Path — Serverless App

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building an event-driven function, HTTP API, or scheduled task
- You do not want to manage servers or containers
- Deployment target is AWS Lambda or GCP Cloud Run

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) — long-running containers on Kubernetes
- [data-pipeline.md](data-pipeline.md) — heavy batch jobs that need more compute

---

## Prerequisites

```bash
bash scripts/env-checker.sh
```

Additional tools needed:

| Tool | Purpose | Install |
|------|---------|---------|
| AWS CLI v2 | Deploy to Lambda | `brew install awscli` |
| Serverless Framework 3+ | Lambda packaging | `npm install -g serverless` |
| gcloud CLI | Deploy to Cloud Run | [cloud.google.com/sdk](https://cloud.google.com/sdk) |
| Terraform 1.7+ | Provision infra | `brew install terraform` |

---

## Flow

```
local dev → pre-commit → CI (build + test + scan)
         → Terraform (infra) → deploy function
         → smoke test → alerts
```

---

## Step 1 — Start local development

Serverless functions run locally with the framework's local invoke:

```bash
# AWS Lambda (Python example)
serverless invoke local --function my-function --data '{"key":"value"}'

# GCP Cloud Run — run as a container locally
docker build -f docker/python/Dockerfile -t my-function .
docker run -p 8080:8080 my-function
```

For functions that depend on a queue, database, or cache, use Docker Compose to spin up dependencies:

```bash
docker compose -f compose/python-postgres-redis/docker-compose.yml up
```

---

## Step 2 — Install pre-commit hooks

```bash
make hooks
```

Config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)  
Details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 3 — Set up the CI pipeline

Copy the appropriate workflow file into `.github/workflows/`:

| Stack | Build + test file |
|-------|-------------------|
| Python | [`ci/github-actions/python/build-test.yml`](../../ci/github-actions/python/build-test.yml) |
| Go | [`ci/github-actions/go/build-test.yml`](../../ci/github-actions/go/build-test.yml) |
| Node.js | [`ci/github-actions/node/build-test.yml`](../../ci/github-actions/node/build-test.yml) |

Add the security scan as a parallel job:

```yaml
uses: ./.github/workflows/reusable-security-scan.yml
```

Source: [`ci/github-actions/_shared/reusable-security-scan.yml`](../../ci/github-actions/_shared/reusable-security-scan.yml)

### Security scans to include

| Scan | File | Blocks merge? |
|------|------|---------------|
| Secret detection | [`security/secret-detection/gitleaks.yml`](../../security/secret-detection/gitleaks.yml) | Yes |
| SAST | [`security/sast/semgrep.yml`](../../security/sast/semgrep.yml) | Yes |
| Dependency audit | [`security/dependency-audit/`](../../security/dependency-audit/) | Advisory |

> Container scanning only applies if you are deploying Cloud Run (where you build an image). Skip it for Lambda zip deployments.

---

## Step 4 — Provision infrastructure

### AWS Lambda

```bash
cd terraform/aws-lambda
terraform init
terraform apply
```

Provisions: Lambda function, IAM role with least-privilege policy, API Gateway or event source, CloudWatch log group.  
Files: [`terraform/aws-lambda/main.tf`](../../terraform/aws-lambda/main.tf) · [`variables.tf`](../../terraform/aws-lambda/variables.tf)

### GCP Cloud Run

Cloud Run infrastructure is provisioned as part of the GKE Terraform module or via `gcloud`:

```bash
gcloud run deploy my-function \
  --image gcr.io/my-project/my-function:$SHA \
  --region us-central1 \
  --no-allow-unauthenticated
```

CI deploy config: [`cd/targets/gcp-gke/cloudbuild.yaml`](../../cd/targets/gcp-gke/cloudbuild.yaml)

---

## Step 5 — Configure secrets

Do not hardcode credentials. Use environment variables sourced from your cloud's secret manager at deploy time.

| Cloud | Approach |
|-------|---------|
| AWS | Lambda reads from SSM Parameter Store or Secrets Manager via IAM role |
| GCP | Cloud Run reads from Secret Manager via Workload Identity |
| CI/CD | OIDC federation — no long-lived keys stored as CI secrets |

OIDC setup guide: [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)  
Secrets strategy: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 6 — Deploy the function

### AWS Lambda (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
uses: cd/targets/aws-lambda/serverless-deploy.yml
```

Source: [`cd/targets/aws-lambda/serverless-deploy.yml`](../../cd/targets/aws-lambda/serverless-deploy.yml)

The workflow:
1. Packages the function code
2. Runs `serverless deploy --stage $ENV`
3. Runs a smoke test (invoke with a test payload)
4. Notifies Slack on success or failure

### GCP Cloud Run (GitHub Actions)

Source: [`cd/targets/gcp-gke/github-actions-deploy.yml`](../../cd/targets/gcp-gke/github-actions-deploy.yml)

---

## Step 7 — Add observability

### AWS Lambda

CloudWatch metrics are automatic. Add structured logging in your function:

```python
import json, logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(json.dumps({"event": event, "request_id": context.aws_request_id}))
```

Add a CloudWatch alarm for error rate and duration breaches — define these in [`terraform/aws-lambda/main.tf`](../../terraform/aws-lambda/main.tf) alongside the function.

### GCP Cloud Run

Cloud Run exports metrics to Cloud Monitoring automatically. Use the OpenTelemetry collector for traces:

Config: [`observability/opentelemetry/collector-config.yaml`](../../observability/opentelemetry/collector-config.yaml)

### Notifications

Wire alerts to your team channel:

```
notifications/slack-notify.yml
notifications/pagerduty-notify.yml
```

---

## Step 8 — Promote across environments

Serverless environments use the same Terraform workspace pattern as containers.

| Environment | Deploy trigger | Image/package tag |
|-------------|----------------|-------------------|
| dev | Every push to `main` | Git SHA |
| staging | PR merge to `release/*` | Git SHA |
| production | Manual approval gate | Git SHA (same as staging) |

Environment strategy: [docs/guides/environment-strategy.md](../guides/environment-strategy.md)

---

## Guardrails

| Rule | Enforced by |
|------|-------------|
| No hardcoded secrets | Gitleaks pre-commit hook + CI scan |
| OIDC auth only (no long-lived AWS/GCP keys in CI) | [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md) |
| Least-privilege IAM role | Terraform module in `terraform/aws-lambda/` |
| Function timeout set explicitly | Required field in `terraform/aws-lambda/variables.tf` |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Steps 1–3, function code, environment variables |
| Platform team | Step 4 (Terraform infra), OIDC setup |
| Security team | Policies in Step 3, IAM role boundaries |
