# DevOps Playbook — Architecture Decision Guide

> **Purpose:** This document answers "which thing should I use?" before you write any code.
> It captures the opinions baked into this repo so contributors and consumers make consistent
> choices without having to reverse-engineer intent from the templates themselves.

---

## How to use this document

1. Find your question in the table of contents
2. Follow the decision tree or table for that domain
3. The answer points you to the right template file
4. If your situation isn't covered, open an issue using the `template-request` template

---

## Table of Contents

1. [Container Strategy](#1-container-strategy)
2. [CI/CD Platform](#2-cicd-platform)
3. [Deployment Target](#3-deployment-target)
4. [Secret Management](#4-secret-management)
5. [Database Migrations](#5-database-migrations)
6. [Kubernetes Workload Patterns](#6-kubernetes-workload-patterns)
7. [Infrastructure Provisioning](#7-infrastructure-provisioning)
8. [Observability](#8-observability)
9. [Security Scanning](#9-security-scanning)
10. [Policy Enforcement](#10-policy-enforcement)
11. [Local Development](#11-local-development)
12. [Networking and TLS](#12-networking-and-tls)
13. [Backup and Recovery](#13-backup-and-recovery)
14. [RBAC and Access Control](#14-rbac-and-access-control)
15. [Cost and Scaling](#15-cost-and-scaling)
16. [Template Maturity Reference](#16-template-maturity-reference)

---

## 1. Container Strategy

### Which Dockerfile do I use?

| Runtime | Use case | Template |
|---|---|---|
| ASP.NET Core | Web API | `docker/dotnet/Dockerfile.api` |
| .NET Worker | Background service, no HTTP | `docker/dotnet/Dockerfile.worker` |
| Angular | Production SPA | `docker/angular/Dockerfile` |
| React | Production SPA | `docker/react/Dockerfile` |
| React | Local dev with hot reload | `docker/react/Dockerfile.dev` |
| FastAPI | Python async API | `docker/python/Dockerfile.fastapi` |
| Flask | Python sync API | `docker/python/Dockerfile.flask` |
| Django | Python full-stack | `docker/python/Dockerfile.django` |
| Express.js | Node.js API | `docker/node/Dockerfile.express` |
| Next.js | Node.js SSR | `docker/node/Dockerfile.nextjs` |
| Spring Boot (Maven) | Java API | `docker/java/Dockerfile.springboot` |
| Spring Boot (Gradle) | Java API | `docker/java/Dockerfile.gradle` |
| Rails | Ruby web app | `docker/ruby/Dockerfile.rails` |
| Go | Any Go service | `docker/go/Dockerfile` |
| Learning / reference | Multi-stage pattern explanation | `docker/_base/Dockerfile.multistage` |
| High-security | Distroless, read-only FS | `docker/_base/security-hardened.Dockerfile` |

### Should I use distroless?

```
Do you have a compliance requirement for minimal attack surface?
├── Yes → use docker/_base/security-hardened.Dockerfile as the pattern
└── No → Is this a Go or statically-linked binary?
    ├── Yes → distroless is zero-friction; worth it
    └── No → use the standard runtime image (node:22-alpine, python:3.13-slim, etc.)
              Alpine is already small; distroless for interpreted runtimes adds complexity
              without proportional security gain for most teams
```

### Base image pinning rules

| Situation | Rule |
|---|---|
| Production Dockerfile | Always pin to a specific version tag (`node:22.4.0-alpine`) |
| Dev Dockerfile | Minor version is acceptable (`node:22-alpine`) |
| Never use | `:latest` — breaks reproducibility and Dependabot drift detection |
| CI base images | Pin by SHA for security-critical steps; minor version for general build steps |

---

## 2. CI/CD Platform

### Which CI platform should I use?

```
Where is your source code?
├── GitHub → use GitHub Actions (ci/github-actions/)
├── GitLab → use GitLab CI (ci/gitlab-ci/)
├── Azure DevOps → use Azure Pipelines (ci/azure-pipelines/)
└── Self-hosted / on-premise → use Jenkins (ci/jenkins/)
    └── Jenkins is the last resort; prefer cloud-native CI when possible
```

### Reusable vs standalone workflow?

| Use case | Pattern |
|---|---|
| Docker build shared across multiple services | `ci/github-actions/_shared/reusable-docker-build.yml` |
| Slack notification shared across pipelines | `ci/github-actions/_shared/reusable-notify-slack.yml` |
| Trivy scan shared across pipelines | `ci/github-actions/_shared/reusable-security-scan.yml` |
| Single-service pipeline that owns its own build | Standalone workflow file |
| Monorepo with multiple services | `ci/github-actions/_strategies/monorepo-affected.yml` |

### When should I use a matrix build?

Use matrix when you need to:
- Test across multiple runtime versions (Node 18 + 20, Python 3.11 + 3.12)
- Deploy to multiple environments in parallel
- Scan multiple Terraform directories simultaneously

Do NOT use matrix when:
- Steps must run sequentially (build → test → deploy)
- Matrix size > 20 combinations (GitHub limits)

### OIDC vs static credentials?

**Always use OIDC.** Static credentials (`AWS_ACCESS_KEY_ID`, `AZURE_CLIENT_SECRET`) are long-lived and cannot be scoped to a specific repository or branch. OIDC tokens are short-lived (15 minutes) and automatically scoped.

| Cloud | OIDC mechanism | Setup guide |
|---|---|---|
| AWS | IAM Role with Web Identity | `docs/guides/github-actions-oidc.md` |
| Azure | Federated Identity on Managed Identity | `docs/guides/github-actions-oidc.md` |
| GCP | Workload Identity Federation | `docs/guides/github-actions-oidc.md` |

---

## 3. Deployment Target

### Where should my application run?

```
Do you need Kubernetes features?
(service mesh, custom autoscaling, StatefulSets, DaemonSets, complex networking)
├── Yes → Which cloud?
│   ├── Azure → terraform/azure-aks/ + cd/targets/azure-aks/
│   ├── AWS → terraform/aws-eks/ + cd/targets/aws-eks/
│   └── GCP → terraform/gcp-gke/ + cd/targets/gcp-gke/
└── No → Is this a stateless web app or API?
    ├── Yes, on Azure → terraform/azure-app-service/ + cd/targets/azure-app-service/
    ├── Yes, on AWS without K8s → terraform/aws-ecs/ + cd/targets/aws-ecs/
    └── Yes, event-driven / short-lived → terraform/aws-lambda/ + cd/targets/aws-lambda/
```

### Helm vs Kustomize?

| Situation | Use |
|---|---|
| Packaging an app for distribution / multiple teams to install | Helm (`cd/helm/`) |
| Environment-specific configuration of manifests you own | Kustomize (`cd/kubernetes/_overlays/`) |
| Both are fine | Prefer Kustomize for internal apps; less indirection |

**Rule of thumb:** If you're writing `{{ .Values.* }}` everywhere and it feels like programming, you might be over-helmifying what should be a simple Kustomize overlay.

### Deployment strategy selection

| Scenario | Pattern | Template |
|---|---|---|
| Standard rolling update | Default Kubernetes rolling update | `cd/kubernetes/_base/deployment.yaml` |
| Zero-downtime blue/green switch | Blue and green Deployments, Service selector swap | `cd/kubernetes/_patterns/blue-green.yaml` |
| Progressive traffic shift | Stable + canary replica ratio | `cd/kubernetes/_patterns/canary.yaml` |
| Database migration before rollout | Init container (short) or Job (long) | `cd/kubernetes/_patterns/db-migration-*.yaml` |
| Startup ordering (wait for dependencies) | Init containers | `cd/kubernetes/_patterns/init-containers.yaml` |

### GitOps or push-based deployment?

```
Does your team do GitOps (Git is the source of truth, cluster pulls state)?
├── Yes → ArgoCD (cd/gitops/argocd/) or Flux (cd/gitops/flux/)
│   ├── Single app → cd/gitops/argocd/application.yaml
│   ├── Many apps from one repo → cd/gitops/argocd/app-of-apps.yaml
│   └── Auto-generate apps per directory → cd/gitops/argocd/applicationset.yaml
└── No → Push-based (GitHub Actions deploys directly to the cluster)
    └── cd/targets/<cloud>/github-actions-deploy.yml
```

---

## 4. Secret Management

### Where should secrets live?

**Never:** hardcoded in code, committed to Git, stored in plain Kubernetes Secrets manifests in Git

| Secret type | Store here | Access via |
|---|---|---|
| Long-lived infrastructure credentials | AWS Secrets Manager / Azure Key Vault / GCP Secret Manager | External Secrets Operator |
| Short-lived cloud credentials in CI | OIDC (no secret storage needed) | GitHub Actions OIDC |
| TLS certificates | cert-manager + Let's Encrypt | Kubernetes Secret (auto-managed) |
| Container registry credentials | `imagePullSecrets` + ECR/ACR token | CI injects at deploy time |
| App configuration (non-secret) | Kubernetes ConfigMap | `envFrom.configMapRef` |
| App secrets | External Secrets Operator → Kubernetes Secret | `envFrom.secretRef` |

### External Secrets Operator (ESO) decision

```
Do you have an existing secret store (AWS SM, Azure KV, GCP SM)?
├── Yes → use ESO with the matching ClusterSecretStore (secrets/external-secrets/)
└── No → Are you starting from scratch?
    ├── AWS → use AWS Secrets Manager (per-secret cost is $0.40/month, very low)
    ├── Azure → use Azure Key Vault (already included with most Azure plans)
    └── GCP → use GCP Secret Manager (first 6 versions/secret free)
```

### Secret rotation approach

| Cloud | Rotation mechanism | Template |
|---|---|---|
| AWS | Secrets Manager native rotation (Lambda) | `secrets/rotation/aws-rotation.yml` |
| Azure | Key Vault + GitHub Actions workflow | `secrets/rotation/azure-rotation.yml` |
| GCP | Secret Manager versioning + GitHub Actions | `secrets/rotation/gcp-rotation.yml` |

**Critical rule:** Rotating the secret value in the store does not automatically update running pods. You must either:
1. Restart the deployment after rotation (`kubectl rollout restart deployment/app`)
2. Use ESO's `refreshInterval` and mount secrets as volumes (volume mounts pick up new versions without restart; env vars do not)

---

## 5. Database Migrations

### Which migration pattern should I use?

```
How long does the migration take?
├── < 2 minutes → init container (cd/kubernetes/_patterns/db-migration-init-container.yaml)
│   Pros: automatic, blocks pod start until done, simple
│   Cons: blocks ALL pods in the rolling update; one stuck migration pauses the rollout
│
├── 2–30 minutes → Kubernetes Job (cd/kubernetes/_patterns/db-migration-job.yaml)
│   Pros: independent lifecycle, can be monitored separately
│   Cons: must be triggered explicitly before the deployment rollout
│
├── Using Helm? → Helm pre-upgrade hook (cd/kubernetes/_patterns/db-migration-hook.yaml)
│   Pros: automatic as part of helm upgrade
│   Cons: blocks helm upgrade; if hook fails, rollback requires manual intervention
│
└── > 30 minutes (large backfills) → out-of-band Job, run independently of deployment
    Cons: app code must be compatible with both old and new schema simultaneously
    (expand/contract pattern — see docs/guides/database-migrations.md)
```

### The golden rules for safe migrations

1. **Backwards compatible first:** Deploy schema changes that are compatible with the OLD app version before deploying the new app version. Never drop a column or rename it in the same release that removes the code using it.
2. **Expand/Contract:** Add new column → deploy new app (reads both) → backfill data → drop old column in a later release.
3. **Idempotent migrations:** Running a migration twice must produce the same result. Use `IF NOT EXISTS`, `IF EXISTS`, upserts.
4. **Test locally first:** Use `make dev` to start the Kind cluster, then run the migration Job against it.

---

## 6. Kubernetes Workload Patterns

### Which workload type do I use?

| App type | Use | Notes |
|---|---|---|
| Stateless web API / frontend | Deployment | Default choice; use HPA for autoscaling |
| Stateful app (database, queue, cache) | StatefulSet | Stable network identity, ordered rollout |
| Node-level daemon (log collector, node exporter) | DaemonSet | Runs one pod per node |
| One-off task | Job | `restartPolicy: Never`; set `activeDeadlineSeconds` |
| Recurring task | CronJob | Wraps a Job; be careful with `concurrencyPolicy` |

### Security context: what must every pod have?

These are enforced by Kyverno (`policy/kyverno/`). If your pod is missing any of these, it will be blocked in production (Enforce mode) or flagged in dev (Audit mode).

| Field | Required value | Kyverno policy |
|---|---|---|
| `spec.securityContext.runAsNonRoot` | `true` | `require-non-root.yaml` |
| `containers[].securityContext.allowPrivilegeEscalation` | `false` | `require-non-root.yaml` |
| `containers[].resources.requests.cpu` | any value | `require-resource-limits.yaml` |
| `containers[].resources.requests.memory` | any value | `require-resource-limits.yaml` |
| `containers[].resources.limits.cpu` | any value | `require-resource-limits.yaml` |
| `containers[].resources.limits.memory` | any value | `require-resource-limits.yaml` |
| `metadata.labels.app` | any non-empty string | `require-labels.yaml` |
| `containers[].securityContext.readOnlyRootFilesystem` | `true` (warn only) | `require-readonly-filesystem.yaml` |

**If your app writes to the filesystem:** mount an `emptyDir` volume at the path it writes to (`/tmp` is the most common). See `cd/kubernetes/_base/deployment.yaml` for the pattern.

### HPA vs VPA vs KEDA?

| Scenario | Use |
|---|---|
| Scale on CPU or memory | HPA (`cd/kubernetes/_base/hpa.yaml`) |
| Right-size resource requests automatically | VPA (not in this repo; add separately) |
| Scale on queue depth, custom metrics, or scale to zero | KEDA (not in this repo; add separately) |
| Don't scale at all | `replicas: N` with no autoscaler |

---

## 7. Infrastructure Provisioning

### Terraform vs Pulumi?

This repo provides both. The choice depends on your team:

| Preference | Use |
|---|---|
| Declarative HCL, strong ecosystem, most common | Terraform (`terraform/`) |
| TypeScript/Python/Go infrastructure code, type safety | Pulumi (`cd/pulumi/`) |

Both produce equivalent infrastructure. Don't use both for the same resource — pick one per team/environment.

### When do I need the bootstrap module?

Always run `terraform/_bootstrap/<cloud>/` first, once, before using any other Terraform module. It creates the remote state backend. Without it, Terraform state is local and will be lost if you lose your machine.

```
Have you run terraform/_bootstrap/<cloud>/ for this cloud and environment before?
├── Yes → uncomment the backend block in the module's main.tf and continue
└── No → run the bootstrap first (terraform/_bootstrap/README.md)
```

### Remote state: which backend?

| Cloud | Backend | Bootstrap template |
|---|---|---|
| AWS | S3 + DynamoDB lock | `terraform/_bootstrap/aws/main.tf` |
| Azure | Azure Blob Storage | `terraform/_bootstrap/azure/main.tf` |
| GCP | GCS bucket | `terraform/_bootstrap/gcp/main.tf` |

Never use local state in production. Never commit `terraform.tfstate` files to Git.

### Terraform workspace vs separate state files?

This repo uses **separate state keys per module** (`eks/terraform.tfstate`, `aks/terraform.tfstate`) rather than Terraform workspaces. Workspaces share the same provider configuration, which makes it harder to use different cloud accounts per environment.

**Pattern used here:** separate state key per module + environment in the key path (e.g., `prod/eks/terraform.tfstate`).

---

## 8. Observability

### Which signal for which question?

| Question | Signal | Tool |
|---|---|---|
| Is my service up and healthy? | Metrics | Prometheus + Alertmanager |
| What happened during an incident at 14:23? | Logs | Loki + Grafana |
| Why is this request slow? | Traces | Tempo + Grafana |
| Is my error rate above the SLO? | Metrics + SLO rules | Prometheus recording rules |
| What did a specific user's request do? | Traces | Tempo |
| Which service is causing cascading failures? | Traces (service map) | Tempo + Grafana |

### Install order

1. Prometheus (`observability/prometheus/`) — alerts and baseline cluster visibility first
2. Loki (`observability/loki/`) — logs next so incidents have both metrics and logs
3. Tempo (`observability/tempo/`) — traces last; most value after metrics and logs are stable
4. OTel sidecar (`observability/opentelemetry/collector-sidecar.yaml`) — add to each app Deployment

### Sampling rate selection

| Environment | Rate | Rationale |
|---|---|---|
| Local / Kind | 100% | Every request traced; debugging is the priority |
| Dev | 100% | Same |
| Staging | 50% | Enough to catch integration issues |
| Production | 10% | Statistically representative; bounded storage cost |

Override `OTEL_TRACES_SAMPLER_ARG` in your Helm values or Kustomize overlay. See `observability/opentelemetry/env-vars/` for language-specific environment variable files.

### Alert severity routing

| Severity | Goes to | Wake someone up? |
|---|---|---|
| `critical` | PagerDuty | Yes — immediately |
| `warning` | Slack | No — review during business hours |

Change the routing in `observability/prometheus/values.yaml` under `alertmanager.config.route`.

---

## 9. Security Scanning

### Which scanner for which purpose?

| Purpose | Tool | When it runs | Template |
|---|---|---|---|
| Secrets in Git history | Gitleaks | Every push + pre-commit | `security/secret-detection/gitleaks.yml` |
| Verified live secrets in PRs | TruffleHog | PR only (expensive) | `security/secret-detection/trufflehog.yml` |
| Container image CVEs | Trivy | After every image build | `security/container-scanning/trivy-scan.yml` |
| Container image CVEs (alternative) | Grype | After every image build | `security/container-scanning/grype-scan.yml` |
| Terraform misconfigurations (broad) | Checkov | Push + PR on terraform/** | `security/iac-scanning/checkov.yml` |
| Terraform cloud-specific checks | tfsec | Push + PR on terraform/** | `security/iac-scanning/tfsec.yml` |
| SAST (code quality + security) | SonarQube/SonarCloud | Push + PR | `security/sast/sonarqube.yml` |
| SAST (fast, no account needed) | Semgrep | Push + PR | `security/sast/semgrep.yml` |
| npm vulnerabilities | npm audit | Weekly schedule | `security/dependency-audit/npm-audit.yml` |
| Python vulnerabilities | pip-audit | Weekly schedule | `security/dependency-audit/pip-audit.yml` |
| .NET NuGet vulnerabilities | dotnet list --vulnerable | Weekly schedule | `security/dependency-audit/nuget-audit.yml` |

### Gitleaks vs TruffleHog: use both

- **Gitleaks** = fast, pattern-based, runs on every commit locally and in CI. First line of defence.
- **TruffleHog** = slow, verification-based (actually calls the API to check if the secret works), runs only on PRs. Second line of defence for verified, live secrets.

You need both. Gitleaks catches historical and pattern matches; TruffleHog confirms a secret is real and active.

### What to do when a scanner fires

```
Scanner found something
├── Is it a false positive?
│   ├── Gitleaks false positive → add to .gitleaks.toml allowlist with a justification comment
│   ├── Checkov false positive → add #checkov:skip=<rule> inline with justification
│   └── tfsec false positive → add #tfsec:ignore:<rule> inline with justification
└── Is it a real finding?
    ├── Secret in git history → rotate immediately, then use git-filter-repo to remove from history
    ├── Container CVE → update base image or the vulnerable package
    ├── IaC misconfiguration → fix the Terraform resource; do not suppress without understanding the risk
    └── Dependency vulnerability → update the dependency; check if a workaround exists first
```

---

## 10. Policy Enforcement

### Kyverno vs static analysis (Checkov/tfsec)?

These are not alternatives — they're complements at different lifecycle stages:

| Stage | Tool | Template location |
|---|---|---|
| Pull request (before merge) | Checkov, tfsec | `security/iac-scanning/` |
| `kubectl apply` (before cluster admission) | Kyverno | `policy/kyverno/` |
| Existing resources in cluster (background scan) | Kyverno (`background: true`) | `policy/kyverno/` |

### Kyverno policy modes — when to use which?

| Mode | Effect | Use when |
|---|---|---|
| `Enforce` | Blocks the resource from being created/updated | Policy is well-understood; existing resources are compliant |
| `Audit` | Admits the resource but records a violation in PolicyReport | Migrating existing workloads; learning what violations exist |
| `Warn` | Admits the resource with a warning in the API response | Developer feedback without hard blocking |

**Migration path:** Audit → fix violations → Enforce. Never go straight to Enforce on a production cluster.

### Which policies are enforced vs audited?

| Policy | Mode | Notes |
|---|---|---|
| `require-non-root` | **Enforce** | Hard requirement; running as root is never acceptable |
| `require-resource-limits` | **Enforce** | Hard requirement; unbounded containers can evict neighbours |
| `require-labels` | **Audit** | Migrate existing workloads first |
| `require-readonly-filesystem` | **Warn** | Gradual adoption |
| `disallow-latest-tag` (prod namespaces) | **Enforce** | Hard requirement in production |
| `disallow-latest-tag` (other namespaces) | **Audit** | Dev/staging can use mutable tags |
| `require-liveness-readiness` | **Audit** | Too many legacy workloads don't have probes yet |

---

## 11. Local Development

### When do I use the devcontainer vs my local machine?

| Scenario | Recommendation |
|---|---|
| First time setting up | Devcontainer — guarantees all tools at the right version |
| Daily development | Either — devcontainer opens in < 30 seconds after first build |
| Debugging a tool installation issue | Local machine + manual install |
| Pair programming / demo | Devcontainer — identical environment |
| GitHub Codespaces | Same devcontainer configuration works automatically |

### Kind vs Minikube vs Docker Desktop Kubernetes?

| Option | Best for | Limitation |
|---|---|---|
| Kind (`local-dev/kind/`) | Reproducing CI-like multi-node setups, testing Kustomize overlays and Helm charts | Requires Docker; slightly more setup |
| Minikube | Single-node experimentation, addon ecosystem | Heavier footprint; less CI parity |
| Docker Desktop Kubernetes | Quickest start, one click | Least portable; weaker parity with production multi-node |

**This repo uses Kind.** The setup script (`local-dev/kind/setup.sh`) is idempotent and produces a 3-node cluster with ingress and a local registry in one command.

### Common local development workflow

```bash
make dev              # start Kind cluster (idempotent)
make lint             # run pre-commit hooks before pushing
make k-apply-dev      # apply Kustomize dev overlay
make k-diff ENV=dev   # preview changes before applying
make load-image IMAGE=my-app:dev-latest  # push a local image into Kind
make dev-down         # tear down when done
```

---

## 12. Networking and TLS

### Ingress or Gateway API?

This repo uses **nginx Ingress** (classic `Ingress` resource). Kubernetes Gateway API is the newer standard but has less widespread tooling support. Switch to Gateway API when your CNI or ingress controller has stable support for it.

### TLS certificate approach

```
What environment?
├── Production → Let's Encrypt production issuer (cert-manager/cluster-issuer-prod.yaml)
│   ⚠️  Rate limit: 5 certs per registered domain per week
│   Always test with staging first
├── Staging / testing → Let's Encrypt staging issuer (cert-manager/cluster-issuer-staging.yaml)
│   No rate limits; certs not trusted by browsers (expected)
└── Internal / local → Self-signed issuer (cert-manager/cluster-issuer-selfsigned.yaml)
    └── Or the Kind cluster (no TLS needed locally)
```

### HTTP-01 vs DNS-01 ACME challenge?

| Challenge | Use when | Limitation |
|---|---|---|
| HTTP-01 | Cluster has public ingress | Can't issue wildcard certs |
| DNS-01 | Wildcard certs needed, or cluster is private | Requires DNS provider API access (Route53, Azure DNS, Cloud DNS) |

### NetworkPolicy: should I use it?

Yes, if your CNI supports it (Calico, Cilium, Azure CNI with policy, GKE with network policy enabled). The templates in `cd/kubernetes/_base/network-policies/` implement a default-deny posture.

**Do not apply `default-deny.yaml` without also applying the allow policies.** Read `cd/kubernetes/_base/network-policies/README.md` first — it explains the correct order.

---

## 13. Backup and Recovery

### What does Velero back up?

| Backed up | NOT backed up |
|---|---|
| Kubernetes object definitions (Deployments, Services, ConfigMaps, Secrets, etc.) | In-memory application state |
| PersistentVolume snapshots (when cloud provider plugin is installed) | Database contents (use DB-native backups) |
| Namespace structure | Container images (they're in the registry) |

**Velero + DB backup = complete DR.** Velero alone is not sufficient if your app has a database.

### Backup frequency guidance

| Data criticality | Backup frequency | Retention | Template |
|---|---|---|---|
| Production cluster config | Daily | 30 snapshots | `backup/velero/schedule.yaml` |
| Production database | Daily + point-in-time | 30 days | `backup/terraform/aws-rds-backup.tf` etc. |
| Staging cluster | Weekly | 7 snapshots | Modify `backup/velero/namespace-backup.yaml` |
| Dev cluster | On-demand only | — | Don't automate dev backups |

### RTO/RPO targets (fill in for your service)

| Tier | Target RPO | Target RTO | Mechanism |
|---|---|---|---|
| Tier 1 (revenue-critical) | 15 minutes | 1 hour | DB PITR + Velero + runbook |
| Tier 2 (business-critical) | 4 hours | 4 hours | Daily DB backup + Velero |
| Tier 3 (internal tools) | 24 hours | 24 hours | Weekly backup |

See `docs/guides/disaster-recovery.md` for restoration procedures.

---

## 14. RBAC and Access Control

### Which role for which persona?

| Persona | Role | Template |
|---|---|---|
| Developer (read-only cluster view) | `devops-playbook:readonly-developer` | `cd/kubernetes/_base/rbac/readonly-developer.yaml` |
| CI/CD pipeline service account | `devops-playbook:ci-deployer` | `cd/kubernetes/_base/rbac/ci-deployer.yaml` |
| Team lead / application owner | `devops-playbook:namespace-admin` | `cd/kubernetes/_base/rbac/namespace-admin.yaml` |
| Platform engineer | `cluster-admin` (built-in) | Granted via your cloud provider IAM |

**Note on secrets access:** The readonly-developer role explicitly denies access to Secrets. Even `list` access to Secrets reveals secret names; `describe` reveals data. Only service accounts that explicitly need secrets should have access.

### How to check what a service account can do

```bash
# List all permissions for a service account
kubectl auth can-i --list \
  --as=system:serviceaccount:<namespace>:<service-account-name>

# Check a specific permission
kubectl auth can-i get secrets \
  --as=system:serviceaccount:production:my-app \
  -n production
```

---

## 15. Cost and Scaling

### Resource sizing starting points

These are starting points from the base deployment. Tune using actual load test data.

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---|---|---|---|---|
| Web API (light) | 100m | 500m | 128Mi | 512Mi |
| Web API (heavy) | 250m | 1000m | 256Mi | 1Gi |
| Background worker | 100m | 500m | 128Mi | 512Mi |
| OTel collector sidecar | 100m | 500m | 128Mi | 512Mi |
| Promtail (DaemonSet) | 50m | 200m | 64Mi | 256Mi |

**Rule:** Set limits to 4–5x the requests for APIs with variable traffic. This gives headroom for spikes without allowing runaway processes to evict neighbours.

### HPA threshold guidance

| Metric | Target | Notes |
|---|---|---|
| CPU utilisation | 70% | Lower than 80% to give headroom before scaling lag |
| Memory utilisation | 80% | Memory doesn't release as cleanly as CPU |
| `minReplicas` | 2 | Never 1 in production — no HA with a single replica |
| `maxReplicas` | Set with cost budget in mind | `HpaMaxReplicasReached` alert fires when you hit this |

### Infracost integration

The drift detection workflow includes Infracost for Terraform cost estimation on PRs. To enable:
1. Get a free API key from `https://www.infracost.io`
2. Add `INFRACOST_API_KEY` to GitHub Actions secrets
3. Cost diff will automatically appear on Terraform PRs

---

## 16. Template Maturity Reference

Every template in this repo carries a maturity badge. Here's what each means:

| Maturity | Meaning | Production ready? |
|---|---|---|
| **Stable** | Tested, well-commented, follows all repo conventions | Yes |
| **Beta** | Works but may have edge cases; less real-world testing | Staging / low-risk production |
| **Experimental** | Proof-of-concept; API or approach may change | Dev / learning only |

### Current maturity summary by area

| Area | Maturity |
|---|---|
| Docker templates (all languages) | Stable |
| GitHub Actions CI (all languages) | Stable |
| Terraform (AWS, Azure, GCP) | Stable |
| Kubernetes manifests + Kustomize | Stable |
| Helm webapp chart | Stable |
| GitOps (ArgoCD, Flux) | Stable |
| Observability (Prometheus, Loki) | Stable |
| Observability (Tempo, OTel) | Stable |
| Security scanning (all tools) | Stable |
| Kyverno policies | Stable |
| NetworkPolicy templates | Stable |
| RBAC templates | Stable |
| Secret rotation workflows | Stable |
| External Secrets Operator bridge | Stable |
| Backup/DR (Velero + DB) | Stable |
| Terraform drift detection | Stable |
| Terraform cost estimation | Stable |
| SLO recording rules | Beta |
| Terraform module tests | Beta |
| AWS Lambda | Beta |
| Database migration patterns | Stable |
| cert-manager bootstrap | Stable |

---

## Quick-reference: "I need to..."

| Task | Go here |
|---|---|
| Containerise a .NET API | `docker/dotnet/Dockerfile.api` |
| Set up CI for a Python project | `ci/github-actions/python/build-test.yml` |
| Deploy to AKS | `terraform/azure-aks/` + `cd/targets/azure-aks/github-actions-deploy.yml` |
| Store a secret securely | `secrets/external-secrets/README.md` |
| Run database migrations safely | `docs/guides/database-migrations.md` |
| Set up TLS certificates | `cd/kubernetes/cert-manager/README.md` |
| Back up my cluster | `backup/velero/README.md` |
| Enforce security policies | `policy/kyverno/README.md` |
| Set up distributed tracing | `observability/opentelemetry/README.md` + `observability/tempo/README.md` |
| Create SLOs and alerts | `observability/prometheus/slos/README.md` |
| Set up OIDC for GitHub Actions | `docs/guides/github-actions-oidc.md` |
| Understand environment differences | `docs/guides/environment-strategy.md` |
| Get started from scratch | `docs/guides/onboarding.md` |
| Understand an architectural decision | `docs/decisions/ADR-00*.md` |
| Find the right template for my scenario | `GETTING_STARTED.md` |
