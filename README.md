
# 🚀 CICD Reference — DevOps Playbook & Starter Repo

> **A battle-tested, production-grade DevOps playbook and starter repository for modern cloud-native teams.**
>
> Built for organizations and teams who want a solid, opinionated starting point — not another hour of Googling. Copy-paste, adapt, and scale with confidence.

---

## Overview


This repository is a comprehensive, real-world reference for building, deploying, and operating applications on Kubernetes, serverless, and cloud platforms. It is designed for:

- **New teams**: Onboard quickly with proven patterns and guardrails
- **Org-wide adoption**: Standardize on best practices, reduce risk, and accelerate delivery
- **Leadership buy-in**: Demonstrate security, compliance, and operational excellence from day one

It provides:

- **Golden paths**: End-to-end, copy-pasteable workflows for microservices, serverless, frontend SPAs, data pipelines, and platform onboarding
- **Ready-to-use CI/CD templates**: GitHub Actions, Azure Pipelines, GitLab CI, Jenkins
- **Infrastructure as Code**: Terraform, Pulumi, Helm, Kustomize
- **Security & compliance**: Built-in scanning, policies, and secret management
- **Observability**: Prometheus, Grafana, Loki, OpenTelemetry, alerting integrations
- **Runbooks & guides**: For onboarding, incident response, disaster recovery, and more


> **Start here:** Pick your [golden path](docs/golden-paths/) and follow it step-by-step. Each path links directly to the files you need to copy or edit.

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
→ Go to [security/](security/) and pick your scanner

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

---

## Golden Paths

Golden paths are **opinionated, end-to-end workflows** that guide you from idea to production, with all best practices and guardrails enforced by default.

| Path | Use case |
|------|----------|
| [kubernetes-microservice.md](docs/golden-paths/kubernetes-microservice.md) | API/microservice on Kubernetes (EKS/AKS/GKE/kind) |
| [serverless-app.md](docs/golden-paths/serverless-app.md) | Lambda/Cloud Run function, event-driven or scheduled |
| [frontend-spa.md](docs/golden-paths/frontend-spa.md) | React/Angular SPA → CDN/App Service |
| [data-pipeline.md](docs/golden-paths/data-pipeline.md) | Batch jobs, CronJobs, ECS tasks |
| [platform-onboarding.md](docs/golden-paths/platform-onboarding.md) | New team onboarding, platform setup |
| [incident-response.md](docs/golden-paths/incident-response.md) | Production incident response & ops |

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
├── security/             # Security scanning integrations
├── quality/              # Code quality configs (SonarQube, linters, formatters)
├── notifications/        # Slack, Teams, PagerDuty alert templates
├── scripts/              # Utility shell scripts
├── docs/                 # Guides, ADRs, diagrams
└── ...
```

---

## Quickstart


## Quickstart

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
- **Disaster recovery**: Velero, DB PITR, runbooks for cluster and DB restore
- **Platform guardrails**: Enforced via Kyverno, IaC, and CI checks

---


## Documentation

- **[docs/golden-paths/](docs/golden-paths/)** — Start here for all workflows
- **[docs/guides/](docs/guides/)** — Deep dives: onboarding, secrets, environments, migrations, DR
- **[docs/runbooks/](docs/runbooks/)** — Incident response, troubleshooting, templates
- **[docs/ARCHITECTURE_DECISION_GUIDE.md](docs/ARCHITECTURE_DECISION_GUIDE.md)** — How decisions are made
- **[docs/repo_structure.md](docs/repo_structure.md)** — Full n-level repo tree with explanations

---


## Who is this for?

- Platform engineers and SREs
- Product teams building APIs, SPAs, or data jobs
- Engineering leadership seeking a proven, production-ready DevOps foundation
- Any team or org ready to standardize and scale cloud-native delivery

---


## Acknowledgements

Inspired by best practices from the open source and cloud-native community. See [docs/decisions/](docs/decisions/) for architecture choices and tradeoffs.
