
# 🚀 CICD Reference — DevOps Playbook & Starter Repo

> **A battle-tested, production-grade DevOps playbook and starter repository for modern cloud-native teams.**
>
> Built for organizations and teams who want a solid, opinionated starting point — not another hour of Googling. Copy-paste, adapt, and scale with confidence.

---

## Overview


This repository is a comprehensive, real-world reference for building, deploying, and operating applications on Kubernetes, serverless, and cloud platforms.

## Purpose And Scope

This repository exists to help teams adopt production-grade DevOps practices quickly, with reusable templates and clear guardrails instead of one-off implementations.

- Establish a standardized baseline for CI/CD, IaC, deployment, security, observability, and FinOps
- Accelerate onboarding and implementation by providing copy-ready, connected examples
- Improve reliability and governance by making safe defaults explicit and repeatable

It is not intended to be a rigid framework. Teams are expected to adapt templates to their environment while preserving core guardrails.

## At A Glance

- Start from workflow guidance in [docs/golden-paths/](docs/golden-paths/)
- Use implementation templates from [docker/](docker/), [ci/](ci/), [cd/](cd/), and [terraform/](terraform/)
- Apply controls from [ci-security/](ci-security/), [secops/](secops/), [policy/](policy/), [secrets/](secrets/), [catalog/](catalog/), and [finops/](finops/)
- Operate with [observability/](observability/) patterns and [docs/runbooks/](docs/runbooks/)

Reference context for maintainers is also available in [.ai/context/repo-summary.md](.ai/context/repo-summary.md).

It is designed for:

- **New teams**: Onboard quickly with proven patterns and guardrails
- **Org-wide adoption**: Standardize on best practices, reduce risk, and accelerate delivery
- **Leadership buy-in**: Demonstrate security, compliance, and operational excellence from day one

It provides:

- **Golden paths**: End-to-end, copy-pasteable workflows for microservices, serverless, frontend SPAs, data pipelines, MLOps, FinOps optimization, SLO-driven development, and service catalog governance
- **Ready-to-use CI/CD templates**: GitHub Actions, Azure Pipelines, GitLab CI, Jenkins
- **Infrastructure as Code**: Terraform, Pulumi, Helm, Kustomize
- **Security & compliance**: Built-in scanning, policies, and secret management
- **Observability**: Prometheus, Grafana, Loki, OpenTelemetry, alerting integrations
- **FinOps & cost governance**: Cost monitoring, budget alerting, rightsizing, chargeback, and CI/CD cost-gating with Infracost
- **Runbooks & guides**: For onboarding, incident response, disaster recovery, and more


> **Start here:** Pick your [golden path](docs/golden-paths/) and follow it step-by-step. Each path links directly to the files you need to copy or edit.
> 
> For local GPU experimentation and fine-tuning, use the dedicated CUDA devcontainer at [.devcontainer/gpu/devcontainer.json](.devcontainer/gpu/devcontainer.json).

---


## Who Is This For?

| Role | How to Use This Repo |
|---|---|
| **Junior Developer** | Copy the file closest to your stack, follow the `# <-- CHANGE THIS` comments |
| **Mid-level Developer** | Use as a baseline, extend with your project's specifics |
| **Tech Lead / Architect** | Fork this repo as your org's internal standard, lock down approved patterns |
| **DevOps Engineer** | Reference for cross-platform equivalencies and deployment targets |
| **Platform/Engineering Leadership** | Adopt as a foundation for security, compliance, and operational excellence |

---

## ⚡ Quick Start — "I just need a file"

**"I need a Dockerfile for my .NET API"**
→ Go to [docker/dotnet/Dockerfile.api](docker/dotnet/Dockerfile.api)

**"I need a GitHub Actions pipeline that builds and tests my React app"**
→ Go to [ci/github-actions/react/build-test.yml](ci/github-actions/react/build-test.yml)

**"I need to deploy to AKS using Azure Pipelines"**
→ Go to [cd/targets/azure-aks/azure-pipelines-deploy.yml](cd/targets/azure-aks/azure-pipelines-deploy.yml)

**"I need a local dev environment with Postgres and Redis"**
→ Go to [compose/python-postgres-redis/docker-compose.yml](compose/python-postgres-redis/docker-compose.yml)

**"I need to add security scanning to my pipeline"**
→ Go to [ci-security/](ci-security/) and pick your scanner

**"I need to provision an EKS cluster with Terraform"**
→ Go to [terraform/aws-eks/](terraform/aws-eks/)

**"I need to set up OIDC auth for GitHub Actions"**
→ Go to [docs/guides/github-actions-oidc.md](docs/guides/github-actions-oidc.md)

**"I need an AWS-native pipeline (CodePipeline)"**
→ Go to [cd/targets/aws-codepipeline/codepipeline.yml](cd/targets/aws-codepipeline/codepipeline.yml)

**"I need a Dockerfile for my Go service"**
→ Go to [docker/go/Dockerfile](docker/go/Dockerfile)

**"I need a CI pipeline for my Rails app"**
→ Go to [ci/github-actions/ruby/build-test.yml](ci/github-actions/ruby/build-test.yml)

**"I need to deploy infrastructure with Pulumi instead of Terraform"**
→ Go to [cd/pulumi/](cd/pulumi/)

**"I need to understand the cost impact of my Terraform PR"**
→ Copy [finops/infracost/.infracost.yml](finops/infracost/.infracost.yml) into your repo and use the CI template for your platform

**"I need to enforce cost labels and resource limits across my cluster"**
→ Deploy the Kyverno policies from [finops/policies/](finops/policies/)

**"I need Grafana dashboards for cloud cost visibility"**
→ Run [finops/scripts/deploy-dashboards.sh](finops/scripts/deploy-dashboards.sh)

**"I need to set up budget alerting in Prometheus"**
→ See [finops/prometheus/budget-alerts.yaml](finops/prometheus/budget-alerts.yaml) and [finops/config/budgets.yaml](finops/config/budgets.yaml)

**"I need to find over-provisioned workloads to cut costs"**
→ Run `python finops/scripts/analyze-rightsizing.py --all-namespaces`

**"I need to operationalize SLOs with burn-rate alerting"**
→ Follow [docs/golden-paths/slo-driven-development.md](docs/golden-paths/slo-driven-development.md)

**"I need to register service ownership and on-call routing"**
→ Follow [docs/golden-paths/service-catalog.md](docs/golden-paths/service-catalog.md)

**"I need end-to-end FinOps optimization from recommendation to PR"**
→ Follow [docs/golden-paths/finops-optimization.md](docs/golden-paths/finops-optimization.md)

---

## Golden Paths

Golden paths are **opinionated, end-to-end workflows** that guide you from idea to production, with all best practices and guardrails enforced by default.

| Path | Use case |
|------|----------|
| [kubernetes-microservice.md](docs/golden-paths/kubernetes-microservice.md) | API/microservice on Kubernetes (EKS/AKS/GKE/kind) |
| [serverless-app.md](docs/golden-paths/serverless-app.md) | Lambda/Cloud Run function, event-driven or scheduled |
| [frontend-spa.md](docs/golden-paths/frontend-spa.md) | React/Angular SPA → CDN/App Service |
| [data-pipeline.md](docs/golden-paths/data-pipeline.md) | Batch jobs, CronJobs, ECS tasks |
| [mlops-workflow.md](docs/golden-paths/mlops-workflow.md) | GPU-backed model training, fine-tuning, and inference delivery |
| [platform-onboarding.md](docs/golden-paths/platform-onboarding.md) | New team onboarding, platform setup |
| [incident-response.md](docs/golden-paths/incident-response.md) | Production incident response & ops |
| [finops-optimization.md](docs/golden-paths/finops-optimization.md) | Cost optimization loop with validated savings |
| [slo-driven-development.md](docs/golden-paths/slo-driven-development.md) | SLO definitions, burn-rate recording rules, and alerting |
| [service-catalog.md](docs/golden-paths/service-catalog.md) | Git-native service registration and ownership governance |

Each path:
- Names the exact files to copy/edit at every step
- Links to runbooks, guides, and policy files
- Encodes non-negotiable guardrails (security, resource limits, etc.)

---


## 📁 Repository Structure

See [docs/repo_structure.md](docs/repo_structure.md) for a full, n-level tree with explanations for every file and folder.

```
├── docker/               # Dockerfiles for every major stack
├── compose/              # Docker Compose for local dev environments
├── ci/                   # CI pipeline templates (GitHub, GitLab, Azure, Jenkins)
├── cd/                   # CD pipeline templates + K8s manifests + Helm charts
├── terraform/            # Infrastructure provisioning (AKS, EKS, GKE, ECS, Lambda)
├── ci-security/          # Security scanning integrations for CI
├── secops/               # Runtime security, supply chain, and compliance operations
├── quality/              # Code quality configs (SonarQube, linters, formatters)
├── notifications/        # Slack, Teams, PagerDuty alert templates
├── scripts/              # Utility shell scripts
├── catalog/              # Git-native service and team ownership catalog
├── finops/               # FinOps: cost monitoring, governance, alerting, reporting
│   ├── dashboards/       #   Grafana dashboards (9 JSON files)
│   ├── policies/         #   Kyverno cost governance policies
│   ├── prometheus/       #   Budget & anomaly alerting rules + Alertmanager configs
│   ├── scripts/          #   Rightsizing, cost reports, tag validation, optimization
│   ├── cicd/             #   Infracost templates (GitHub Actions, Azure Pipelines, GitLab)
│   ├── helm/             #   Kubecost / OpenCost / VPA Helm values
│   ├── kubernetes/       #   CronJob for monthly cost reports
│   ├── config/           #   Budget thresholds per cost center
│   └── docs/             #   Installation, runbooks, workflow guides
├── docs/                 # Guides, ADRs, diagrams
└── ...
```

---

## Quick Start

1. **Check your environment:**
   ```bash
   bash scripts/env-checker.sh
   ```
2. **Pick your golden path:**
   - [Kubernetes microservice](docs/golden-paths/kubernetes-microservice.md)
   - [Serverless app](docs/golden-paths/serverless-app.md)
   - [Frontend SPA](docs/golden-paths/frontend-spa.md)
   - [Data pipeline](docs/golden-paths/data-pipeline.md)
   - [Platform onboarding](docs/golden-paths/platform-onboarding.md)
   - [FinOps optimization](docs/golden-paths/finops-optimization.md)
   - [SLO-driven development](docs/golden-paths/slo-driven-development.md)
   - [Service catalog registration](docs/golden-paths/service-catalog.md)
3. **Follow the steps:**
   - Each path tells you which files to copy/edit, and links to runbooks and guides.


> **No secrets in code.** Use External Secrets Operator and OIDC federation for all cloud credentials. See [docs/guides/secrets-management.md](docs/guides/secrets-management.md).

---


## Key Patterns & Guardrails

- **Multi-stage Docker builds**: Build stage never ships to prod; non-root user in final stage; `.dockerignore` for every Dockerfile; `HEALTHCHECK` included; pinned base image versions
- **CI/CD**: Modular, reusable workflows for build, test, scan, deploy
- **GitOps**: ArgoCD, overlays, and patterns for safe, automated delivery
- **Security**: Gitleaks, Trivy, Semgrep, Snyk, Kyverno policies
- **Observability**: Prometheus rules, Grafana dashboards, SLOs, alert routing
- **Service ownership governance**: Catalog validation, CODEOWNERS generation, and admission checks
- **Disaster recovery**: Velero, DB PITR, runbooks for cluster and DB restore
- **Platform guardrails**: Enforced via Kyverno, IaC, and CI checks
- **FinOps governance**: Cost labels enforced at admission, resource limits required, GPU workloads gated, budget alerts at 80/100/120%, PR-level cost estimation via Infracost

---


## 💰 FinOps — Cloud Cost Governance

This repository includes a **production-grade FinOps system** that brings cost visibility, governance, and optimization into the CI/CD lifecycle — from Terraform PRs all the way through to monthly chargeback reports.

### Architecture

```
 CI/CD Pipelines  (GitHub Actions / Azure Pipelines / GitLab CI)
  └── Infracost ──► Shows monthly cost impact on every Terraform PR

 Kubernetes Cluster
  ├── Kyverno Policies         Admission-time cost governance
  │    ├── require-cost-labels       blocks pods missing finops.org/* labels
  │    ├── enforce-resource-limits   blocks unconstrained containers
  │    ├── gpu-approval-gate         requires explicit GPU approval annotation
  │    └── require-pdb-large-wkld   PDB required for workloads > 4 CPU / 8Gi
  │
  ├── Kubecost / OpenCost      Real-time cost per namespace / workload
  ├── VPA Recommender          CPU & memory rightsizing recommendations
  └── CronJob                  Monthly chargeback/showback reports → S3/Blob/GCS

 Prometheus + Alertmanager
  ├── budget-alerts            80% / 100% / 120% threshold alerts per cost center
  ├── anomaly-alerts           Cost spike detection vs 7-day baseline
  └── tag-compliance-alerts    Fires when > 5% pods lack required cost labels

 Grafana  (9 dashboards)
  ├── Cost Overview            ├── Budget Tracking
  ├── Cost Breakdown           ├── Anomaly Detection
  ├── Rightsizing Opportunities├── Tag Compliance
  ├── Multi-Cloud Comparison   ├── Reserved Capacity
  └── Optimization Opportunities
```

### Components

| Component | Purpose | Location |
|-----------|---------|----------|
| **Kubecost / OpenCost** | Real-time cost monitoring per workload | [`finops/helm/`](finops/helm/) |
| **VPA** | Rightsizing recommendations (recommender-only) | [`finops/helm/vpa-values.yaml`](finops/helm/vpa-values.yaml) |
| **Kyverno Policies** | Admission-time cost governance (4 policies) | [`finops/policies/`](finops/policies/) |
| **Infracost CI/CD** | PR-level Terraform cost estimation (3 platforms) | [`finops/cicd/`](finops/cicd/) |
| **Budget Alerts** | Prometheus rules at 80 / 100 / 120% spend | [`finops/prometheus/budget-alerts.yaml`](finops/prometheus/budget-alerts.yaml) |
| **Anomaly Detection** | Cost spike vs 7-day baseline + new namespace | [`finops/prometheus/anomaly-alerts.yaml`](finops/prometheus/anomaly-alerts.yaml) |
| **Alertmanager Routing** | Slack + PagerDuty per severity / cost center | [`finops/prometheus/alertmanager-budget-config.yaml`](finops/prometheus/alertmanager-budget-config.yaml) |
| **Cost Reports** | Monthly CSV + JSON chargeback with export | [`finops/scripts/generate-cost-report.py`](finops/scripts/generate-cost-report.py) |
| **Grafana Dashboards** | 9 dashboards — full cost visibility | [`finops/dashboards/`](finops/dashboards/) |
| **Optimization Scripts** | Rightsizing, idle volumes, reserved capacity | [`finops/scripts/`](finops/scripts/) |

### FinOps Quick Start

```bash
# 1. Install cost monitoring
./finops/scripts/install-cost-monitoring.sh --tool kubecost

# 2. Deploy Kyverno policies (audit mode first — non-blocking)
./finops/scripts/deploy-policies.sh --audit-mode

# 3. Import all 9 Grafana dashboards
export GRAFANA_API_KEY=your-key
./finops/scripts/deploy-dashboards.sh

# 4. Validate cost label compliance
python finops/scripts/validate-cost-tags.py --all-namespaces

# 5. Find rightsizing opportunities
python finops/scripts/analyze-rightsizing.py --all-namespaces
```

### Required Cost Labels

All pods **must** carry these labels — enforced at admission by Kyverno:

```yaml
metadata:
  labels:
    finops.org/costcenter: "engineering"    # must match an entry in finops/config/budgets.yaml
    finops.org/environment: "production"    # dev | staging | production
```

> 📖 **Full FinOps documentation:** [finops/README.md](finops/README.md)  
> 🏷️ **Cost tagging schema:** [finops/docs/cost-tagging-schema.md](finops/docs/cost-tagging-schema.md)  
> 🚀 **Installation guide:** [finops/docs/installation.md](finops/docs/installation.md)  
> 🔍 **Investigate a cost spike:** [finops/docs/runbooks/investigate-cost-spike.md](finops/docs/runbooks/investigate-cost-spike.md)

---


## Documentation


- **[docs/golden-paths/](docs/golden-paths/)** — Start here for all workflows, including the new MLOps path
- **[docs/guides/](docs/guides/)** — Deep dives: onboarding, secrets, environments, migrations, DR
- **[docs/runbooks/](docs/runbooks/)** — Incident response, troubleshooting, templates
- **[docs/ARCHITECTURE_DECISION_GUIDE.md](docs/ARCHITECTURE_DECISION_GUIDE.md)** — How decisions are made
- **[docs/repo_structure.md](docs/repo_structure.md)** — Full n-level repo tree with explanations
- **[.devcontainer/gpu/README.md](.devcontainer/gpu/README.md)** — Local CUDA/GPU devcontainer usage
- **[finops/README.md](finops/README.md)** — FinOps architecture, components, quick-start, and full documentation index

---


## Acknowledgements

Inspired by best practices from the open source and cloud-native community. See [docs/decisions/](docs/decisions/) for architecture choices and tradeoffs.
