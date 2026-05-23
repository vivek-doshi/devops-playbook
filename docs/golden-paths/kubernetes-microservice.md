# Golden Path — Kubernetes Microservice

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building a backend API or microservice
- Deployment target is Kubernetes (EKS, AKS, GKE, or local kind)
- You want CI/CD, security scanning, and observability wired up by default

Not the right path? See:
- [frontend-spa.md](frontend-spa.md) — React or Angular app
- [serverless-app.md](serverless-app.md) — Lambda / Cloud Run
- [data-pipeline.md](data-pipeline.md) — batch jobs and scheduled tasks
- [mobile-backend.md](mobile-backend.md) — BFF for mobile apps (API versioning, OAuth/OIDC, push notifications, rate limiting)
- [database-migrations.md](database-migrations.md) — end-to-end workflow for zero-downtime schema migrations
- [multi-tenant-saas.md](multi-tenant-saas.md) — namespace-per-tenant isolation, automated onboarding, billing instrumentation

---

## Prerequisites

Run the environment checker before anything else:

```bash
bash scripts/env-checker.sh
```

Required: Git 2.40+, Docker Desktop 4.x, kubectl 1.29+, kind 0.24+, Helm 3.14+, pre-commit 3.x.  
Full list with install links: [docs/guides/onboarding.md](../guides/onboarding.md)

---

## Flow

```
local dev → pre-commit → CI (build + test + scan) → image push
         → GitOps update → ArgoCD sync → Kubernetes → alerts
```

---

## Step 1 — Start local environment

```bash
# Create a kind cluster, local registry, and ingress-nginx
bash local-dev/kind/setup.sh
```

This script:
1. Creates a kind cluster named `devops-playbook`
2. Starts a local container registry at `localhost:5001`
3. Installs ingress-nginx
4. Creates a `dev` namespace and applies the dev Kustomize overlay

Config: [`local-dev/kind/kind-config.yaml`](../../local-dev/kind/kind-config.yaml)  
Script: [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh)

To tear down:

```bash
bash local-dev/kind/teardown.sh
```

To run your service with its dependencies (DB, cache) locally:

```bash
docker compose -f compose/microservices-example/docker-compose.yml up
```

---

## Step 2 — Install pre-commit hooks

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

Hooks run on every `git commit` and `git push`. What they check:

| Hook | Tool | Catches |
|------|------|---------|
| Secret scan | Gitleaks | Credentials committed to Git |
| IaC format | terraform fmt | Malformatted Terraform |

Config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)  
Full details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 3 — Set up the CI pipeline

Copy the workflow file for your stack into `.github/workflows/`:

| Stack | File |
|-------|------|
| Python | [`ci/github-actions/python/build-test.yml`](../../ci/github-actions/python/build-test.yml) |
| Go | [`ci/github-actions/go/build-test.yml`](../../ci/github-actions/go/build-test.yml) |
| .NET | [`ci/github-actions/dotnet/build-test.yml`](../../ci/github-actions/dotnet/build-test.yml) |
| Java | [`ci/github-actions/java/build-test.yml`](../../ci/github-actions/java/build-test.yml) |

The pipeline runs: dependency install → build → unit tests → coverage → lint.

Add the security scan step by referencing the shared workflow:

```yaml
# .github/workflows/build.yml  (add after build-test)
uses: ./.github/workflows/reusable-security-scan.yml
```

Source: [`ci/github-actions/_shared/reusable-security-scan.yml`](../../ci/github-actions/_shared/reusable-security-scan.yml)

---

## Step 4 — Build and push the Docker image

Use the reusable build workflow — it enforces multi-stage build, non-root user, and SHA-pinned tags:

```yaml
uses: ./.github/workflows/reusable-docker-build.yml
with:
  image-name: my-service
  dockerfile: docker/<stack>/Dockerfile
```

Source: [`ci/github-actions/_shared/reusable-docker-build.yml`](../../ci/github-actions/_shared/reusable-docker-build.yml)  
Dockerfile templates: [`docker/<stack>/Dockerfile`](../../docker/)

> **Rule:** Never push or deploy with the `latest` tag. The pipeline tags images with the Git SHA.

---

## Step 5 — Add security scanning

Wire these three scans into CI. They run in parallel after the build step.

| What | File | Blocks merge? |
|------|------|---------------|
| Secrets in image | [`security/secret-detection/gitleaks.yml`](../../security/secret-detection/gitleaks.yml) | Yes |
| Container vulnerabilities | [`security/container-scanning/trivy-scan.yml`](../../security/container-scanning/trivy-scan.yml) | Yes (HIGH/CRITICAL) |
| Source code (SAST) | [`security/sast/semgrep.yml`](../../security/sast/semgrep.yml) | Yes |
| Dependency audit | [`security/dependency-audit/`](../../security/dependency-audit/) | Advisory |

---

## Step 6 — Provision the cluster

> Skip this step if a cluster already exists. Check with your platform team first.

### Bootstrap remote state (first time only)

Before provisioning any cluster, set up the shared Terraform state backend. Run this once per cloud account:

```bash
# AWS
cd terraform/_bootstrap/aws
terraform init
terraform plan -out=tfplan
terraform apply tfplan
# Copy the output bucket/table names into terraform/aws-eks/main.tf backend block

# Azure
cd terraform/_bootstrap/azure
terraform init && terraform apply

# GCP
cd terraform/_bootstrap/gcp
terraform init && terraform apply
```

Full instructions: [`terraform/_bootstrap/README.md`](../../terraform/_bootstrap/README.md)

### Provision the cluster

```bash
cd terraform/aws-eks    # or azure-aks / gcp-gke
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Provisions: Kubernetes cluster, container registry, VPC/networking, IAM roles.

Directories: [`terraform/aws-eks/`](../../terraform/aws-eks/) · [`terraform/azure-aks/`](../../terraform/azure-aks/) · [`terraform/gcp-gke/`](../../terraform/gcp-gke/)

---

## Step 7 — Provision the database

Most microservices need a database. Provision it alongside the cluster using the backup-enabled Terraform templates:

```bash
# Add backup.tf to your cluster module, then re-apply
# AWS RDS with PITR + cross-region replica
cp terraform/aws-eks/backup.tf my-infra/

# Azure PostgreSQL with geo-redundant backup
cp terraform/azure-aks/backup.tf my-infra/

# GCP Cloud SQL with PITR + read replica
cp terraform/gcp-gke/backup.tf my-infra/

terraform apply
```

Files:
- [`terraform/aws-eks/backup.tf`](../../terraform/aws-eks/backup.tf) — RDS with PITR, cross-region replica, CloudWatch alarm
- [`terraform/azure-aks/backup.tf`](../../terraform/azure-aks/backup.tf) — PostgreSQL Flexible Server with geo-redundant backup
- [`terraform/gcp-gke/backup.tf`](../../terraform/gcp-gke/backup.tf) — Cloud SQL with PITR, cross-region replica

---

## Step 8 — Create Kubernetes manifests

Start from the base manifests and add environment overlays:

```
cd/kubernetes/
  _base/              ← deployment, service, ingress, HPA, PDB, network policy, RBAC, VPA
  _overlays/dev/      ← dev-specific patches (1 replica, relaxed resources)
  _overlays/staging/  ← staging patches
  _overlays/prod/     ← production patches (3 replicas, tight PDB, pinned image tag)
  _patterns/          ← canary, blue-green, db-migration hooks
```

Key files to copy and adapt:

| File | Purpose |
|------|---------|
| [`_base/deployment.yaml`](../../cd/kubernetes/_base/deployment.yaml) | Deployment with health checks, security context |
| [`_base/hpa.yaml`](../../cd/kubernetes/_base/hpa.yaml) | Horizontal pod autoscaler |
| [`_base/pdb.yaml`](../../cd/kubernetes/_base/pdb.yaml) | Pod disruption budget |
| [`_base/networkpolicy.yaml`](../../cd/kubernetes/_base/networkpolicy.yaml) | Network isolation |
| [`_base/vpa.yaml`](../../cd/kubernetes/_base/vpa.yaml) | Vertical pod autoscaler (Off mode) |
| [`_base/rbac.yaml`](../../cd/kubernetes/_base/rbac.yaml) | ServiceAccounts and RBAC roles |
| [`_patterns/canary.yaml`](../../cd/kubernetes/_patterns/canary.yaml) | Canary rollout |
| [`_patterns/blue-green.yaml`](../../cd/kubernetes/_patterns/blue-green.yaml) | Blue/Green rollout |

All services must declare `readinessProbe` and `livenessProbe`. The Kyverno policy [`policy/kyverno/require-liveness-readiness.yaml`](../../policy/kyverno/require-liveness-readiness.yaml) will block deployments that do not.

Test manifests locally before pushing:

```bash
# Preview what Kustomize will generate
kubectl kustomize cd/kubernetes/_overlays/dev

# Run conftest policy checks
conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes
```

---

## Step 9 — Handle database migrations

If your service applies schema changes, use the appropriate migration pattern:

| Scenario | Pattern |
|----------|---------|
| Short migration (< 5 min), app cannot start with old schema | [Init container](../../cd/kubernetes/_patterns/db-migration-init-container.yaml) |
| Long migration (> 5 min) or must run once across cluster | [Pre-deploy Job](../../cd/kubernetes/_patterns/db-migration-job.yaml) |
| Helm-managed release | [Pre-upgrade hook](../../cd/kubernetes/_patterns/db-migration-hook.yaml) |

Full guide: [docs/guides/database-migrations.md](../guides/database-migrations.md)

---

## Step 10 — Configure secrets

Do not put secrets in manifests. Use External Secrets Operator to sync from your cloud provider's vault:

| Cloud | Store config |
|-------|-------------|
| AWS | [`secrets/external-secrets/aws-secret-store.yaml`](../../secrets/external-secrets/aws-secret-store.yaml) |
| Azure | [`secrets/external-secrets/azure-secret-store.yaml`](../../secrets/external-secrets/azure-secret-store.yaml) |
| GCP | [`secrets/external-secrets/gcp-secret-store.yaml`](../../secrets/external-secrets/gcp-secret-store.yaml) |

Reference secret in a manifest: [`secrets/external-secrets/example-external-secret.yaml`](../../secrets/external-secrets/example-external-secret.yaml)  
Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 11 — Deploy via GitOps (ArgoCD)

### Bootstrap ArgoCD (platform team, first time only)

If ArgoCD is not yet installed on the cluster:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment argocd-server -n argocd --timeout=120s
```

### Register your service

```bash
# Copy and edit the Application manifest
cp cd/gitops/argocd/application.yaml \
   cd/gitops/argocd/my-service.yaml

# Edit repoURL, path, and destination namespace
# Then apply
kubectl apply -f cd/gitops/argocd/my-service.yaml
```

Key files:

| File | Purpose |
|------|---------|
| [`cd/gitops/argocd/application.yaml`](../../cd/gitops/argocd/application.yaml) | Single app definition |
| [`cd/gitops/argocd/applicationset.yaml`](../../cd/gitops/argocd/applicationset.yaml) | Multi-environment generator |
| [`cd/gitops/argocd/app-of-apps.yaml`](../../cd/gitops/argocd/app-of-apps.yaml) | App-of-apps bootstrap |

Once merged, ArgoCD syncs `dev` automatically. Promotion to `staging` and `prod` is a PR that updates the image tag in the relevant Kustomize overlay (`_overlays/prod/kustomization.yaml`).

Environment strategy: [docs/guides/environment-strategy.md](../guides/environment-strategy.md)

---

## Step 12 — Add observability

### Metrics and alerts

Apply the Prometheus rules for your service:

```
observability/prometheus/
  alerts/       ← alert rules (pod crash, latency, error rate)
  slos/         ← SLO burn-rate alerts
  dashboards/   ← Grafana dashboard JSON
  values.yaml   ← kube-prometheus-stack Helm values
```

Start with [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/) — copy the pod-level alerts and edit the `app` label selector to match your service.

Define an SLO:

```bash
# Copy and edit the availability SLO template
cp observability/prometheus/slos/availability-slo.yaml \
   observability/prometheus/slos/my-service-availability-slo.yaml
# Replace all "my-service" references with your service's job label
kubectl apply -f observability/prometheus/slos/my-service-availability-slo.yaml
```

Import the SLO dashboard into Grafana:

```bash
kubectl apply -f observability/prometheus/dashboards/slo-burn-rate-configmap.yaml
```

### Distributed tracing

Add the OpenTelemetry collector sidecar to your deployment:

```bash
# Apply the collector ConfigMap first
kubectl apply -f observability/opentelemetry/collector-config.yaml -n <namespace>

# Then patch the Deployment to add the sidecar
kubectl patch deployment <name> -n <namespace> \
  --patch-file observability/opentelemetry/collector-sidecar.yaml
```

Load language-specific env vars:

```bash
# .NET, Python, or Java
kubectl create configmap otel-dotnet-env \
  --from-env-file=observability/opentelemetry/env-vars/dotnet.env \
  -n <namespace>
```

Files: [`observability/opentelemetry/`](../../observability/opentelemetry/)

### Notifications

Wire alert routing to your team channel:

```
notifications/slack-notify.yml
notifications/pagerduty-notify.yml
notifications/teams-notify.yml
```

---

## Step 13 — Enable backup (production only)

```bash
# Install Velero (first time per cluster)
bash backup/velero/aws-install.sh

# Apply the backup schedule
kubectl apply -f backup/velero/schedule.yaml

# Take an on-demand snapshot before a major release
kubectl apply -f backup/velero/namespace-backup.yaml
```

Files: [`backup/velero/`](../../backup/velero/)

---

## FinOps Checkpoints

> Complete these steps before promoting to **production**. They are part of the standard workflow — not optional extras.

### FinOps Checkpoint 1 — Verify cost labels

All Pods must have `finops.org/costcenter` and `finops.org/environment` labels. The `require-cost-labels` Kyverno policy will block deployment if they are missing.

```yaml
# In your Deployment pod template spec:
metadata:
  labels:
    app: my-service
    finops.org/costcenter: "engineering"       # Required
    finops.org/environment: "production"       # Required: dev | staging | production
    finops.org/team: "platform"                # Optional
    finops.org/project: "my-service"           # Optional
```

Validate before deploying:
```bash
python finops/scripts/validate-cost-tags.py --namespace <your-namespace>
```

Cost tagging schema: [`finops/docs/cost-tagging-schema.md`](../../finops/docs/cost-tagging-schema.md)

---

### FinOps Checkpoint 2 — Review VPA recommendations (pre-production)

Before deploying to production, check if VPA has recommendations for your workload. VPA needs at least 24 hours of data from staging.

```bash
# Check VPA recommendations and cost impact
python finops/scripts/analyze-rightsizing.py --namespace <staging-namespace>
```

What to check:
- If VPA recommends **lower** resources → update your manifests to match (free savings)
- If savings > 20% → this is **high priority** — address before production deploy
- If no recommendations → VPA needs more data (ensure staging has been running 24h+)

View in Grafana: [FinOps — Rightsizing Opportunities](https://grafana.internal.company.com/d/finops-rightsizing)

---

### FinOps Checkpoint 3 — Confirm resource requests align with team budget

Before deploying a new service, estimate its monthly cost contribution:

```bash
# Quick cost estimate: CPU * $0.048/hr * 730 + RAM * $0.006/hr * 730
# Example: 0.5 CPU + 512Mi = (0.5 * 0.048 + 0.5 * 0.006) * 730 ≈ $19.71/month
```

Then verify the team's budget has headroom:
- Check current spend in [FinOps — Budget Tracking dashboard](https://grafana.internal.company.com/d/finops-budget-tracking)
- If adding > $500/month to a cost center → notify the FinOps team

---

### FinOps PR Checklist

Include the FinOps checklist in your PR for infrastructure changes:  
[`finops/templates/pr-checklist.md`](../../finops/templates/pr-checklist.md)

---

## Guardrails

These Kyverno policies are enforced cluster-wide. Deployments that violate them will be rejected:

| Policy file | Rule |
|-------------|------|
| [`policy/kyverno/disallow-latest-tag.yaml`](../../policy/kyverno/disallow-latest-tag.yaml) | No `latest` image tags |
| [`policy/kyverno/require-resource-limits.yaml`](../../policy/kyverno/require-resource-limits.yaml) | CPU and memory limits required |
| [`policy/kyverno/require-liveness-readiness.yaml`](../../policy/kyverno/require-liveness-readiness.yaml) | Health probes required |
| [`policy/kyverno/require-non-root.yaml`](../../policy/kyverno/require-non-root.yaml) | Containers must not run as root |
| [`policy/kyverno/require-readonly-filesystem.yaml`](../../policy/kyverno/require-readonly-filesystem.yaml) | Read-only root filesystem |
| [`policy/kyverno/require-labels.yaml`](../../policy/kyverno/require-labels.yaml) | `app`, `version`, `team` labels required |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Steps 1–5, 8–10, service manifests |
| Platform team | Steps 6–7 (Terraform infra, cluster, DB), Step 11 (ArgoCD bootstrap), cluster policies |
| Security team | Policies enforced in Step 5 |

---

## Runbooks

When something goes wrong in production, start here:

- [`docs/runbooks/podcrashloobackoff.md`](../runbooks/podcrashloobackoff.md) — pod crash loop diagnosis
- [`docs/runbooks/template.md`](../runbooks/template.md) — write a new runbook for your service
- Full incident procedure: [incident-response.md](incident-response.md)
