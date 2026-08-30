# Golden Path — Platform Onboarding

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## Who this is for

A new team joining the organisation, or an existing team adopting this playbook for the first time.

By the end of this path your team will have:

- A working local development environment on every engineer's machine
- Pre-commit hooks installed and enforced
- A GitHub repository wired to CI templates
- A named Kubernetes namespace with RBAC and network isolation
- Secrets management configured
- An on-call rotation and alert routing set up

This path does not build an application. It gets your team's platform foundations in place so that the application paths ([Kubernetes Microservice](kubernetes-microservice.md), [Frontend SPA](frontend-spa.md), etc.) work on first attempt.

---

## Prerequisites

Every engineer on the team runs this before anything else:

```bash
bash scripts/env-checker.sh
```

The script checks for the following tools and prints install instructions for any that are missing:

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Git | 2.40 | Version control |
| Docker Desktop | 4.x | Container builds and local kind nodes |
| kubectl | 1.29 | Manage Kubernetes resources |
| kind | 0.24 | Local Kubernetes cluster |
| Helm | 3.14 | Kubernetes package management |
| Terraform | 1.6 | Infrastructure provisioning |
| pre-commit | 3.x | Git hook management |
| AWS CLI / Azure CLI / gcloud | Latest | Cloud authentication |

Install guides:
- Docker Desktop: https://docs.docker.com/desktop/
- kubectl: https://kubernetes.io/docs/tasks/tools/
- kind: https://kind.sigs.k8s.io/docs/user/quick-start/
- Helm: https://helm.sh/docs/intro/install/
- Terraform: https://developer.hashicorp.com/terraform/install
- pre-commit: https://pre-commit.com/#install

---

## Flow

```
local toolchain → clone + bootstrap → kind cluster → hooks
→ GitHub repo setup → namespace + RBAC → secrets store
→ observability → alert routing → choose an app path
```

---

## Step 1 — Set up individual workstations

Each engineer on the team completes this independently.

```bash
# 1. Clone the repo
git clone https://github.com/your-org/cicd-reference.git
cd cicd-reference

# 2. Verify the toolchain
bash scripts/env-checker.sh

# 3. Install pre-commit hooks (once per clone)
pre-commit install
pre-commit install --hook-type commit-msg
```

The pre-commit config at [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml) runs the following hooks on every commit:

| Hook | What it checks |
|------|---------------|
| Gitleaks | Secrets and credentials committed to Git |
| terraform fmt | Malformatted Terraform files |
| trailing-whitespace | Whitespace hygiene |
| end-of-file-fixer | Missing newlines |

Full details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 2 — Start the shared local cluster

For local development the repo ships a `kind` cluster that mirrors the production overlay structure. Each engineer runs this on their own machine.

```bash
bash local-dev/kind/setup.sh
```

This script:
1. Creates a kind cluster named `devops-playbook`
2. Starts a local container registry at `localhost:5001`
3. Installs ingress-nginx on the control-plane node
4. Applies the dev Kustomize overlay (`cd/kubernetes/_overlays/dev/`)
5. Installs the webapp Helm chart for smoke testing

When it completes, two endpoints are available:
- Kustomize overlay: `http://localhost/`
- Helm chart: `http://localhost/helm`

Config: [`local-dev/kind/kind-config.yaml`](../../local-dev/kind/kind-config.yaml)
Script: [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh)

To load a locally built image into the cluster:

```bash
bash local-dev/kind/load-image.sh my-app:dev-latest path/to/Dockerfile
```

To tear down cleanly:

```bash
bash local-dev/kind/teardown.sh
```

---

## Step 3 — Set up your GitHub repository

### Branch protection

Apply these settings in **Settings → Branches → Add rule** for the `main` branch:

- Require pull request reviews before merging (minimum 1 reviewer)
- Require status checks to pass before merging — add your CI workflow names
- Require branches to be up to date before merging
- Do not allow bypassing the above settings

Branching strategy: [docs/guides/branching-strategy.md](../guides/branching-strategy.md)

### Conventional commits

Enforce commit message format so release automation (changelog generation, version bumps) works correctly. Add this workflow to `.github/workflows/`:

```bash
cp ci/github-actions/_shared/pr-conventional-commit.yml \
   .github/workflows/pr-conventional-commit.yml
```

Source: [`ci/github-actions/_shared/pr-conventional-commit.yml`](../../ci/github-actions/_shared/pr-conventional-commit.yml)

The workflow validates:
- Every commit in a PR follows the `type(scope): description` format
- The PR title follows the same format (used as the squash-merge commit message)
- PR size stays within configurable line-count thresholds

Create a `commitlint.config.js` at the repo root:

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always',
      ['feat', 'fix', 'docs', 'style', 'refactor',
       'perf', 'test', 'chore', 'ci', 'build', 'revert']],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
  },
};
```

Commit format guide: [docs/guides/conventional-commits.md](../guides/conventional-commits.md)

### Release strategy

Choose one approach and add it to `.github/workflows/`:

| Strategy | When to use | File |
|----------|-------------|------|
| Release Please | Libraries and versioned APIs (creates release PRs) | [`ci/github-actions/_strategies/release-please.yml`](../../ci/github-actions/_strategies/release-please.yml) |
| Semantic Release | Apps with continuous delivery (cuts releases on every merge) | [`ci/github-actions/_strategies/semantic-release.yml`](../../ci/github-actions/_strategies/semantic-release.yml) |

Versioning guide: [docs/guides/versioning-strategy.md](../guides/versioning-strategy.md)

### OIDC federation (keyless cloud authentication)

Set up OIDC federation between GitHub Actions and your cloud provider. This replaces long-lived static credentials stored as GitHub Secrets with short-lived tokens that are automatically rotated.

```bash
# AWS — create an OIDC provider and IAM role
# Follow: docs/guides/github-actions-oidc.md

# Azure — create an app registration with federated credentials
# Follow: docs/guides/github-actions-oidc.md

# GCP — configure Workload Identity Federation
# Follow: docs/guides/github-actions-oidc.md
```

OIDC setup guide: [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)

---

## Step 4 — Bootstrap remote Terraform state (first time only)

Before any Terraform is applied, create the shared remote state backend. This is a one-time operation per cloud account, performed by an engineer with administrative access — not from CI.

```bash
# AWS — creates S3 bucket + DynamoDB lock table
cd terraform/_bootstrap/aws
terraform init
terraform plan -out=tfplan
terraform apply tfplan
# Note the outputs: state_bucket_name, lock_table_name, backend_region

# Azure — creates Storage Account + Blob container
cd terraform/_bootstrap/azure
terraform init && terraform apply

# GCP — creates GCS bucket
cd terraform/_bootstrap/gcp
terraform init && terraform apply
```

After applying, copy the output values into the `backend` block of your workload modules (`terraform/aws-eks/main.tf`, etc.) and uncomment it, then run `terraform init -migrate-state` inside each module.

Full instructions: [`terraform/_bootstrap/README.md`](../../terraform/_bootstrap/README.md)

---

## Step 5 — Request your Kubernetes namespace

Open a PR to the platform team's infrastructure repository adding your team's namespace configuration. The platform team reviews and applies it. Your namespace will include:

| Resource | Template |
|----------|----------|
| Namespace with `environment` label | [`cd/kubernetes/_base/`](../../cd/kubernetes/_base/) |
| RBAC — developer read-only role | [`cd/kubernetes/_base/rbac/readonly-developer.yaml`](../../cd/kubernetes/_base/rbac/readonly-developer.yaml) |
| RBAC — CI deployer role | [`cd/kubernetes/_base/rbac/ci-deployer.yaml`](../../cd/kubernetes/_base/rbac/ci-deployer.yaml) |
| RBAC — namespace admin role | [`cd/kubernetes/_base/rbac/namespace-admin.yaml`](../../cd/kubernetes/_base/rbac/namespace-admin.yaml) |
| Network policy — default deny all | [`cd/kubernetes/_base/network-policies/default-deny.yaml`](../../cd/kubernetes/_base/network-policies/default-deny.yaml) |
| Network policy — allow DNS egress | [`cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml`](../../cd/kubernetes/_base/network-policies/allow-egress-to-dns.yaml) |

Verify your namespace exists and you have access:

```bash
kubectl get namespace <your-namespace>
kubectl auth can-i list pods -n <your-namespace>
```

---

## Step 6 — Configure secrets management

Install External Secrets Operator on the cluster (platform team, once per cluster):

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace \
  --set installCRDs=true
```

Apply the SecretStore for your cloud. Edit the file first to set your vault URL, region, and service account annotations:

```bash
# AWS
kubectl apply -f secrets/external-secrets/aws-secret-store.yaml

# Azure
kubectl apply -f secrets/external-secrets/azure-secret-store.yaml

# GCP
kubectl apply -f secrets/external-secrets/gcp-secret-store.yaml
```

Create your first ExternalSecret using the template:

```bash
cp secrets/external-secrets/example-external-secret.yaml \
   secrets/external-secrets/my-app-secrets.yaml
# Edit: name, namespace, secretStoreRef, remoteRef keys
kubectl apply -f secrets/external-secrets/my-app-secrets.yaml

# Verify it synced
kubectl get externalsecret my-app-secrets -n <namespace>
kubectl get secret my-app-secrets -n <namespace>
```

Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 7 — Enforce cluster policies

The following Kyverno policies apply cluster-wide. Review them now so your services are compliant before any deployment attempt.

Install Kyverno (platform team, once per cluster):

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version 3.1.4

kubectl apply -f policy/kyverno/
```

Policies your workloads must comply with:

| Policy | File | Mode | What it enforces |
|--------|------|------|-----------------|
| No `latest` tag | [`policy/kyverno/disallow-latest-tag.yaml`](../../policy/kyverno/disallow-latest-tag.yaml) | Enforce (prod) / Audit (other) | Images must be pinned to a specific tag |
| Resource limits required | [`policy/kyverno/require-resource-limits.yaml`](../../policy/kyverno/require-resource-limits.yaml) | Enforce | CPU and memory requests + limits on all containers |
| Health probes required | [`policy/kyverno/require-liveness-readiness.yaml`](../../policy/kyverno/require-liveness-readiness.yaml) | Audit | Liveness + readiness probes on multi-replica Deployments |
| Non-root required | [`policy/kyverno/require-non-root.yaml`](../../policy/kyverno/require-non-root.yaml) | Enforce | `runAsNonRoot: true`, `allowPrivilegeEscalation: false` |
| Read-only filesystem | [`policy/kyverno/require-readonly-filesystem.yaml`](../../policy/kyverno/require-readonly-filesystem.yaml) | Warn | `readOnlyRootFilesystem: true` |
| Labels required | [`policy/kyverno/require-labels.yaml`](../../policy/kyverno/require-labels.yaml) | Audit | `app` + `version` on Deployments; `environment` on Namespaces |

Check for violations in your namespace:

```bash
kubectl get policyreport -n <your-namespace>
kubectl describe policyreport -n <your-namespace> | grep -A 5 "fail"
```

Full policy guide: [`policy/kyverno/README.md`](../../policy/kyverno/README.md)

Also run Conftest checks locally before pushing manifests:

```bash
conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes
```

---

## Step 8 — Wire up observability

The platform team maintains the Prometheus stack. Install it if it is not already running:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f observability/prometheus/values.yaml
```

Your team configures alert rules and dashboards for your own services:

**Alert rules** — copy a template and edit the `job` label to match your service:

```bash
cp observability/prometheus/alerts/pod-alerts.yaml \
   observability/prometheus/alerts/my-service-alerts.yaml
# Edit: job label selectors, runbook_url values
kubectl apply -f observability/prometheus/alerts/my-service-alerts.yaml
```

**SLO burn-rate alerts** — define your availability target:

```bash
cp observability/prometheus/slos/availability-slo.yaml \
   observability/prometheus/slos/my-service-availability-slo.yaml
# Edit: all "my-service" references, SLO_TARGET annotation
kubectl apply -f observability/prometheus/slos/my-service-availability-slo.yaml
```

**Grafana dashboards** — apply the SLO dashboard ConfigMap so Grafana auto-discovers it:

```bash
kubectl apply -f observability/prometheus/dashboards/slo-burn-rate-configmap.yaml
```

**Loki log aggregation** — install the Loki stack alongside Prometheus:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack \
  --version 2.10.2 \
  --namespace monitoring \
  -f observability/loki/values.yaml

kubectl apply -f observability/loki/grafana-datasource.yaml
```

**Tempo distributed tracing** — install Tempo for trace storage:

```bash
helm install tempo grafana/tempo \
  --version 1.9.0 \
  --namespace monitoring \
  -f observability/tempo/values.yaml

kubectl apply -f observability/tempo/grafana-datasource.yaml
```

Full observability guide: [`observability/README.md`](../../observability/README.md)

---

## Step 9 — Set up alert routing

Decide where failure alerts go and add the receiver credentials to Alertmanager. Edit the Alertmanager config in [`observability/prometheus/values.yaml`](../../observability/prometheus/values.yaml) under `alertmanager.config`.

| Channel | Config file | Use for |
|---------|------------|---------|
| Slack | [`notifications/slack-notify.yml`](../../notifications/slack-notify.yml) | Dev and staging alerts |
| PagerDuty | [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml) | Production on-call paging |
| Microsoft Teams | [`notifications/teams-notify.yml`](../../notifications/teams-notify.yml) | Teams using Microsoft 365 |
| Grafana annotations | [`notifications/grafana-notify.yml`](../../notifications/grafana-notify.yml) | Deployment markers on dashboards |
| Datadog | [`notifications/datadog-notify.yml`](../../notifications/datadog-notify.yml) | DORA metrics and APM correlation |

To test that routing works, fire a test alert and confirm it reaches the right channel:

```bash
# Port-forward to Alertmanager
kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093:9093

# Send a test alert
curl -XPOST http://localhost:9093/api/v1/alerts \
  -H 'Content-Type: application/json' \
  -d '[{"labels":{"alertname":"TestAlert","severity":"warning","team":"<your-team>"}}]'
```

---

## Step 10 — Write your first runbook

Before going to production, write a runbook for your service's most likely failure modes. A runbook gives the on-call engineer a clear, tested procedure so they do not have to debug from scratch at 2am.

```bash
cp docs/runbooks/template.md \
   docs/runbooks/<your-service>-crash-loop.md
# Fill in: symptoms, diagnosis steps, remediation options, escalation path
```

Template: [`docs/runbooks/template.md`](../runbooks/template.md)
Example: [`docs/runbooks/podcrashloobackoff.md`](../runbooks/podcrashloobackoff.md)

Link the runbook from your alert annotation so it surfaces automatically when the alert fires:

```yaml
# In your PrometheusRule
annotations:
  runbook_url: "https://github.com/your-org/repo/blob/main/docs/runbooks/<your-service>-crash-loop.md"
```

---

## Step 11 — Choose your application path

With platform foundations in place, pick the right path for what you're building:

| What you're building | Path |
|---------------------|------|
| Backend API / microservice | [Kubernetes Microservice](kubernetes-microservice.md) |
| React or Angular app | [Frontend SPA](frontend-spa.md) |
| Lambda / Cloud Run function | [Serverless App](serverless-app.md) |
| Batch job / CronJob | [Data Pipeline](data-pipeline.md) |

---

## Production readiness checklist

Before any service goes to `prod`, confirm all of the following:

- [ ] `bash scripts/env-checker.sh` passes on all engineers' machines
- [ ] `pre-commit install` run on all engineers' clones
- [ ] Branch protection enabled on `main` with required CI checks
- [ ] OIDC federation configured — no long-lived cloud credentials in GitHub Secrets
- [ ] Remote Terraform state backend configured and in use
- [ ] Namespace exists with correct RBAC and NetworkPolicy applied
- [ ] External Secrets store configured, tested, and at least one ExternalSecret syncing
- [ ] Kyverno policies installed — `kubectl get policyreport -n <ns>` shows no failures
- [ ] At least one alert rule deployed — fire it manually to confirm routing works
- [ ] PagerDuty on-call rotation set up for the team
- [ ] Runbook written for at least the top two most likely failure modes
- [ ] Runbook URLs referenced in alert annotations
- [ ] Velero backup schedule applied to the production namespace

---

## Responsibilities

| Role | Owns |
|------|------|
| Platform team | Steps 4 (Terraform bootstrap), 5 (namespace provisioning), 7 (Kyverno install), 8 (Prometheus/Loki/Tempo stack) |
| Team lead / tech lead | Steps 3 (repo setup), 9 (alert routing), production readiness sign-off |
| Every engineer | Steps 1–2 (local toolchain and hooks), Step 10 (runbook authoring) |
