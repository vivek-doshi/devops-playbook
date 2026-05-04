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
make dev
```

This creates a kind cluster, local registry at `localhost:5001`, and installs ingress-nginx.  
Config: [`local-dev/kind/kind-config.yaml`](../../local-dev/kind/kind-config.yaml)  
Script: [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh)

To run your service with its dependencies (DB, cache) locally:

```bash
# from your service directory
docker compose -f compose/microservices-example/docker-compose.yml up
```

---

## Step 2 — Install pre-commit hooks

```bash
make hooks
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

> Skip this step if a cluster already exists.

```bash
cd terraform/aws-eks    # or azure-aks / gcp-gke
terraform init
terraform apply
```

Provisions: Kubernetes cluster, container registry, VPC/networking.

Directories: [`terraform/aws-eks/`](../../terraform/aws-eks/) · [`terraform/azure-aks/`](../../terraform/azure-aks/) · [`terraform/gcp-gke/`](../../terraform/gcp-gke/)

---

## Step 7 — Create Kubernetes manifests

Start from the base manifests and add environment overlays:

```
cd/kubernetes/
  _base/              ← deployment, service, ingress, HPA, PDB, network policy
  _overlays/dev/      ← dev-specific patches (replicas, resource limits)
  _overlays/staging/
  _overlays/prod/
  _patterns/          ← canary, blue-green, db-migration hooks
```

Key files to copy and adapt:

| File | Purpose |
|------|---------|
| [`_base/deployment.yaml`](../../cd/kubernetes/_base/deployment.yaml) | Deployment with health checks |
| [`_base/hpa.yaml`](../../cd/kubernetes/_base/hpa.yaml) | Horizontal pod autoscaler |
| [`_base/pdb.yaml`](../../cd/kubernetes/_base/pdb.yaml) | Pod disruption budget |
| [`_base/networkpolicy.yaml`](../../cd/kubernetes/_base/networkpolicy.yaml) | Network isolation |
| [`_patterns/canary.yaml`](../../cd/kubernetes/_patterns/canary.yaml) | Canary rollout |
| [`_patterns/blue-green.yaml`](../../cd/kubernetes/_patterns/blue-green.yaml) | Blue/Green rollout |

All services must declare `readinessProbe` and `livenessProbe`. The Kyverno policy [`policy/kyverno/require-liveness-readiness.yaml`](../../policy/kyverno/require-liveness-readiness.yaml) will block deployments that do not.

---

## Step 8 — Configure secrets

Do not put secrets in manifests. Use External Secrets Operator to sync from your cloud provider's vault:

| Cloud | Store config |
|-------|-------------|
| AWS | [`secrets/external-secrets/aws-secret-store.yaml`](../../secrets/external-secrets/aws-secret-store.yaml) |
| Azure | [`secrets/external-secrets/azure-secret-store.yaml`](../../secrets/external-secrets/azure-secret-store.yaml) |
| GCP | [`secrets/external-secrets/gcp-secret-store.yaml`](../../secrets/external-secrets/gcp-secret-store.yaml) |

Reference secret in a manifest: [`secrets/external-secrets/example-external-secret.yaml`](../../secrets/external-secrets/example-external-secret.yaml)  
Background: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 9 — Deploy via GitOps (ArgoCD)

Register your service with ArgoCD:

```bash
# Copy and edit the Application manifest
cp cd/gitops/argocd/application.yaml \
   cd/gitops/argocd/my-service.yaml
```

Key files:

| File | Purpose |
|------|---------|
| [`cd/gitops/argocd/application.yaml`](../../cd/gitops/argocd/application.yaml) | Single app definition |
| [`cd/gitops/argocd/applicationset.yaml`](../../cd/gitops/argocd/applicationset.yaml) | Multi-environment generator |
| [`cd/gitops/argocd/app-of-apps.yaml`](../../cd/gitops/argocd/app-of-apps.yaml) | App-of-apps bootstrap |

Once merged, ArgoCD syncs `dev` automatically. Promotion to `staging` and `prod` is a PR that updates the image tag in the relevant overlay.  
Full promotion flow: [docs/guides/environment-strategy.md](../guides/environment-strategy.md)

---

## Step 10 — Add observability

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

### Distributed tracing

Add the OpenTelemetry collector sidecar to your deployment:

```yaml
# paste into your deployment.yaml containers list
# source: observability/opentelemetry/collector-sidecar.yaml
```

File: [`observability/opentelemetry/collector-sidecar.yaml`](../../observability/opentelemetry/collector-sidecar.yaml)

### Notifications

Wire alert routing to your team channel. Copy and configure one of:

```
notifications/slack-notify.yml
notifications/pagerduty-notify.yml
notifications/teams-notify.yml
```

---

## Step 11 — Enable backup (production only)

```bash
# Install Velero and configure schedule
bash backup/velero/aws-install.sh        # or edit for your cloud
kubectl apply -f backup/velero/schedule.yaml
kubectl apply -f backup/velero/namespace-backup.yaml
```

Files: [`backup/velero/`](../../backup/velero/)

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
| Developer | Steps 1–5, 7–8, service manifests |
| Platform team | Steps 6, 9 (ArgoCD setup), cluster policies |
| Security team | Policies enforced in Step 5 |

---

## Runbooks

When something goes wrong in production, start here:

- [`docs/runbooks/podcrashloobackoff.md`](../runbooks/podcrashloobackoff.md) — pod crash loop diagnosis
- [`docs/runbooks/template.md`](../runbooks/template.md) — write a new runbook for your service
- Full incident procedure: [incident-response.md](incident-response.md)
