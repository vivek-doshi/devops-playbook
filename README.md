<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# 🚀 CICD Reference Kit

> **A battle-tested, copy-paste-ready reference library for CI/CD pipelines, Docker configurations, and Kubernetes deployments.**
>
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
> Built for teams who want a solid, opinionated starting point — not another hour of Googling.

---

## Who Is This For?

<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Role | How to Use This Repo |
|---|---|
| **Junior Developer** | Copy the file closest to your stack, follow the `# <-- CHANGE THIS` comments |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Mid-level Developer** | Use as a baseline, extend with your project's specifics |
| **Tech Lead / Architect** | Fork this repo as your org's internal standard, lock down approved patterns |
| **DevOps Engineer** | Reference for cross-platform equivalencies and deployment targets |

<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## ⚡ Quick Start — "I just need a file"

**"I need a Dockerfile for my .NET API"**
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
→ Go to [`docker/dotnet/Dockerfile.api`](docker/dotnet/Dockerfile.api)

**"I need a GitHub Actions pipeline that builds and tests my React app"**
→ Go to [`ci/github-actions/react/build-test.yml`](ci/github-actions/react/build-test.yml)

<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**"I need to deploy to AKS using Azure Pipelines"**
→ Go to [`cd/targets/azure-aks/azure-pipelines-deploy.yml`](cd/targets/azure-aks/azure-pipelines-deploy.yml)

**"I need a local dev environment with Postgres and Redis"**
<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
→ Go to [`compose/python-postgres-redis/docker-compose.yml`](compose/python-postgres-redis/docker-compose.yml)

**"I need to add security scanning to my pipeline"**
→ Go to [`security/`](security/) and pick your scanner

<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**"I need to provision an EKS cluster with Terraform"**
→ Go to [`terraform/aws-eks/`](terraform/aws-eks/)

**"I need to set up OIDC auth for GitHub Actions"**
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
→ Go to [`docs/guides/github-actions-oidc.md`](docs/guides/github-actions-oidc.md)

**"I need an AWS-native pipeline (CodePipeline)"**
→ Go to [`cd/targets/aws-codepipeline/codepipeline.yml`](cd/targets/aws-codepipeline/codepipeline.yml)

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**"I need a Dockerfile for my Go service"**
→ Go to [`docker/go/Dockerfile`](docker/go/Dockerfile)

**"I need a CI pipeline for my Rails app"**
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
→ Go to [`ci/github-actions/ruby/build-test.yml`](ci/github-actions/ruby/build-test.yml)

**"I need to deploy infrastructure with Pulumi instead of Terraform"**
→ Go to [`cd/pulumi/`](cd/pulumi/)

<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 📁 Repository Structure

```
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
devops-playbook/
├── docker/               # Dockerfiles for every major stack
├── compose/              # Docker Compose for local dev environments
<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── ci/                   # CI pipeline templates (GitHub, GitLab, Azure, Jenkins)
├── cd/                   # CD pipeline templates + K8s manifests + Helm charts
├── terraform/            # Infrastructure provisioning (AKS, EKS, GKE, ECS, Lambda)
<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── security/             # Security scanning integrations
├── quality/              # Code quality configs (SonarQube, linters, formatters)
├── notifications/        # Slack, Teams, PagerDuty alert templates
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── scripts/              # Utility shell scripts
└── docs/                 # Guides, ADRs, diagrams
```

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 🐳 `docker/` — Dockerfiles

Every Dockerfile here is production-ready with multi-stage builds, non-root users, and minimal final images. Each one has comments explaining every non-obvious decision.

<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
docker/
├── dotnet/
<!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── Dockerfile.api          # ASP.NET Core Web API — multi-stage, SDK build → runtime image
│   ├── Dockerfile.worker       # .NET Background Service / Worker — no HTTP port exposed
│   └── .dockerignore           # Excludes bin/, obj/, *.user, secrets
<!-- Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── angular/
│   ├── Dockerfile              # Multi-stage: Node build → nginx serve (production)
<!-- Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── nginx.conf              # Custom nginx config with gzip, security headers, SPA routing
│   └── .dockerignore           # Excludes node_modules, dist
│
<!-- Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── react/
│   ├── Dockerfile              # Multi-stage: Node build → nginx serve (production)
│   ├── Dockerfile.dev          # Development only — hot reload via volume mount
<!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── nginx.conf              # nginx config tuned for React SPA routing
│
├── python/
<!-- Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── Dockerfile.flask        # Flask app — gunicorn as WSGI server
│   ├── Dockerfile.fastapi      # FastAPI — uvicorn with worker config
│   ├── Dockerfile.django       # Django — gunicorn, collectstatic baked in
<!-- Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── .dockerignore           # Excludes __pycache__, .venv, *.pyc
│
├── node/
<!-- Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── Dockerfile.express      # Express.js API — production-hardened, non-root
│   └── Dockerfile.nextjs       # Next.js — standalone output mode for minimal image
│
<!-- Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── java/
│   ├── Dockerfile.springboot   # Spring Boot — layered JAR for better cache reuse
│   └── Dockerfile.gradle       # Gradle-based build — multi-stage with Gradle cache
<!-- Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── go/
│   ├── Dockerfile              # Multi-stage: golang build → distroless static binary
<!-- Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── .dockerignore
│
├── ruby/
<!-- Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── Dockerfile.rails        # Multi-stage: bundle install + assets → ruby-slim runtime
│   └── .dockerignore
│
<!-- Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── _base/
    ├── Dockerfile.multistage   # Heavily annotated teaching example explaining every layer
    └── security-hardened.Dockerfile  # Distroless final image, read-only FS, dropped capabilities
<!-- Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

**Key patterns used across all Dockerfiles:**
- Multi-stage builds (build stage never ships to prod)
<!-- Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Non-root user created and used in final stage
- `.dockerignore` provided alongside every Dockerfile
- `HEALTHCHECK` instructions included
<!-- Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Pinned base image versions (no `latest` tags)

---

## 🧩 `compose/` — Local Development Environments

<!-- Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Docker Compose files for spinning up full local stacks. These are **dev-only** — they prioritise convenience (volume mounts, exposed ports) over security.

```
compose/
<!-- Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── dotnet-sqlserver/
│   └── docker-compose.yml      # .NET API + SQL Server + Seq (structured logging UI)
│
<!-- Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── python-postgres-redis/
│   └── docker-compose.yml      # Python app + PostgreSQL + Redis + pgAdmin UI
│
<!-- Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── microservices-example/
│   └── docker-compose.yml      # 3-service example with shared network, API gateway pattern
│
<!-- Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── _templates/
    └── docker-compose.base.yml # Template with every common pattern annotated — start here
```

<!-- Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**What `_templates/docker-compose.base.yml` covers:** named volumes, named networks, healthcheck dependencies (`depends_on` with condition), env file usage, service profiles for optional tools.

---

## ⚙️ `ci/` — Continuous Integration Pipelines

<!-- Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
CI templates organised first by **platform**, then by **tech stack**. Pick your platform folder, then find your language.

### Platform Overview

| Platform | Best For | Notes |
<!-- Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|---|---|---|
| `github-actions/` | GitHub-hosted repos, OSS projects | Native OIDC to cloud, reusable workflows |
| `gitlab-ci/` | Self-hosted GitLab, enterprise | Powerful include/extend system |
<!-- Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| `azure-pipelines/` | Azure DevOps shops | Deep Azure integration, YAML templates |
| `jenkins/` | Legacy enterprise, custom infra | Groovy Jenkinsfiles, shared libraries |

```
<!-- Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
ci/
├── github-actions/
│   ├── dotnet/
<!-- Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── build-test.yml          # Restore, build, test, publish coverage
│   │   ├── sonar-scan.yml          # SonarCloud integration with PR decoration
│   │   └── docker-publish.yml      # Build image, push to registry (GHCR or ACR)
<!-- Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │
│   ├── angular/
│   │   ├── build-test.yml          # npm ci, lint, test (Jest/Karma), build
<!-- Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── lighthouse-audit.yml    # Automated Lighthouse CI score gating
│   │
│   ├── react/
<!-- Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── build-test.yml          # npm ci, lint (ESLint), test, build
│   │
│   ├── python/
<!-- Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── build-test.yml          # pip install, pytest, coverage report, ruff lint
│   │   └── security-scan.yml       # bandit (SAST) + pip-audit (dependency check)
│   │
<!-- Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── java/
│   │   └── build-test.yml          # Maven and Gradle variants in one file using matrix
│   │
<!-- Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── _shared/                    # Reusable workflows (call with `uses:`)
│   │   ├── reusable-docker-build.yml   # Build + push image, outputs image digest
│   │   ├── reusable-security-scan.yml  # Trivy scan, uploads SARIF to GitHub Security tab
<!-- Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── reusable-notify-slack.yml   # Success/failure Slack notification
│   │
│   ├── go/
<!-- Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── build-test.yml          # go vet, golangci-lint, test with race + coverage
│   │
│   ├── ruby/
<!-- Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── build-test.yml          # bundler, RuboCop, Brakeman, minitest/RSpec, coverage
│   │
│   ├── terraform/
<!-- Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── plan-apply.yml          # Plan on PR, apply on merge — OIDC auth to any cloud
│   │
│   └── _strategies/                # Advanced pipeline patterns
<!-- Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│       ├── matrix-build.yml        # Test across multiple OS / runtime versions simultaneously
│       ├── monorepo-affected.yml   # Only trigger jobs for services that actually changed
│       └── release-please.yml      # Automated changelog + version bump PRs
<!-- Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── gitlab-ci/
│   ├── dotnet/
<!-- Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── .gitlab-ci.yml          # Stages: build → test → sonar → docker → tag
│   │
│   ├── python/
<!-- Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── .gitlab-ci.yml          # Stages: lint → test → security → docker
│   │
│   ├── terraform/
<!-- Note 61: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── .gitlab-ci.yml          # Validate → plan → apply (manual gate)
│   │
│   ├── _includes/                  # Reusable CI fragments (use with `include:`)
<!-- Note 62: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── .docker-build.yml       # Kaniko-based image build (works in rootless runners)
│   │   ├── .sast-scan.yml          # GitLab SAST template with custom rules
│   │   └── .notify.yml             # Slack/Teams notification jobs
<!-- Note 63: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │
│   └── _strategies/
│       ├── parent-child-pipeline.yml   # Trigger separate pipelines per service in a monorepo
<!-- Note 64: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│       └── dynamic-pipeline.yml        # Generate pipeline YAML at runtime based on changed files
│
├── azure-pipelines/
<!-- Note 65: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── dotnet/
│   │   └── azure-pipelines.yml     # Build, test, SonarQube, publish artifact, docker push
│   │
<!-- Note 66: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── angular/
│   │   └── azure-pipelines.yml     # Build, test, docker push to ACR
│   │
<!-- Note 67: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── python/
│   │   └── azure-pipelines.yml     # Lint, test with pytest, publish test results
│   │
<!-- Note 68: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── _templates/                 # Azure YAML templates (use with `extends:`)
│   │   ├── build-template.yml      # Reusable build steps parametrised by language
│   │   ├── docker-template.yml     # ACR login + build + push
<!-- Note 69: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── test-template.yml       # Test run + result publishing + coverage
│   │
│   ├── terraform/
<!-- Note 70: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── azure-pipelines.yml     # Plan on PR, apply on merge via AzureCLI task
│   │
│   └── _strategies/
<!-- Note 71: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│       ├── variable-groups.yml     # Linking pipeline variables to Azure Key Vault secrets
│       └── deployment-gates.yml    # Pre/post-deployment approval gates and health checks
│
<!-- Note 72: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── jenkins/
    ├── dotnet/
    │   └── Jenkinsfile             # Declarative pipeline: build → test → docker → deploy
    <!-- Note 73: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    │
    ├── python/
    │   └── Jenkinsfile             # Declarative pipeline with virtual env and pytest
    <!-- Note 74: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    │
    └── _shared/
        └── shared-library-example/ # Example of a Jenkins Shared Library structure (vars/, src/)
<!-- Note 75: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

### What Every CI Template Includes

Every CI file in this repo covers: dependency caching, build step, unit test run, test result publishing, code coverage threshold enforcement, and image build trigger on the main branch.

<!-- Note 76: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 🚢 `cd/` — Continuous Deployment

Deployment configs split into three concerns: **what runs on Kubernetes** (manifests), **how it's packaged** (Helm), and **where it goes** (cloud targets).

<!-- Note 77: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
cd/
├── kubernetes/                     # Raw Kubernetes manifests using Kustomize
<!-- Note 78: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── _base/                      # The single source of truth — environment-agnostic
│   │   ├── deployment.yaml         # Deployment with resource limits, liveness/readiness probes
│   │   ├── service.yaml            # ClusterIP service (change to LoadBalancer for external)
<!-- Note 79: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── ingress.yaml            # Ingress with TLS, annotations for nginx/traefik
│   │   ├── hpa.yaml                # HorizontalPodAutoscaler — CPU and memory based
│   │   ├── configmap.yaml          # Non-secret config (env vars, config files)
<!-- Note 80: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── kustomization.yaml      # Wires all the above together
│   │
│   ├── _overlays/                  # Environment-specific overrides (Kustomize patches)
<!-- Note 81: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── dev/                    # Low replicas, relaxed limits, debug logging
│   │   ├── staging/                # Production-like config, but smaller scale
│   │   └── prod/                   # Full replicas, strict limits, PodDisruptionBudget
<!-- Note 82: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │
│   └── _patterns/                  # Advanced deployment strategies
│       ├── blue-green.yaml         # Two identical environments, instant traffic switch
<!-- Note 83: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│       ├── canary.yaml             # Route % of traffic to new version before full rollout
│       └── init-containers.yaml    # DB migration init container pattern
│
<!-- Note 84: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── helm/                           # Helm chart templates
│   ├── webapp/                     # Generic web application chart
│   │   ├── Chart.yaml              # Chart metadata — name, version, appVersion
<!-- Note 85: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── values.yaml             # All defaults documented with comments
│   │   ├── values.dev.yaml         # Dev environment overrides
│   │   ├── values.prod.yaml        # Production overrides (higher replicas, stricter limits)
<!-- Note 86: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── templates/              # Kubernetes resource templates using Helm templating
│   │
│   └── microservice/               # Microservice-specific chart with sidecar support
<!-- Note 87: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── targets/                        # Cloud-specific deployment pipeline files
│   ├── azure-aks/
<!-- Note 88: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── github-actions-deploy.yml       # OIDC auth → kubeconfig → kubectl/helm deploy
│   │   ├── gitlab-deploy.yml               # GitLab CI job deploying to AKS
│   │   └── azure-pipelines-deploy.yml      # Azure Pipelines task-based AKS deploy
<!-- Note 89: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │
│   ├── aws-eks/
│   │   ├── github-actions-deploy.yml       # OIDC auth → aws eks update-kubeconfig → deploy
<!-- Note 90: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── gitlab-deploy.yml               # GitLab CI deploying to EKS with IAM role
│   │
│   ├── gcp-gke/
<!-- Note 91: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── github-actions-deploy.yml       # Workload Identity → gcloud auth → deploy
│   │   └── cloudbuild.yaml                 # Native GCP Cloud Build pipeline to GKE
│   │
<!-- Note 92: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── azure-app-service/                  # For teams not yet on Kubernetes
│   │   └── github-actions-deploy.yml       # Build → publish → deploy to App Service slot
│   │
<!-- Note 93: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── aws-ecs/
│   │   └── github-actions-deploy.yml       # Push image → update ECS task definition → deploy
│   │
<!-- Note 94: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── aws-lambda/
│   │   └── serverless-deploy.yml           # Serverless Framework or SAM deploy workflow
│   │
<!-- Note 95: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── aws-codepipeline/               # AWS-native CI/CD (no GitHub/GitLab)
│       ├── codepipeline.yml                # CloudFormation: Source → Build → Approve → Deploy
│       └── buildspec.yml                   # CodeBuild spec: Docker build + test + push to ECR
<!-- Note 96: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── pulumi/                          # Pulumi IaC (TypeScript) — alternative to Terraform
│   ├── deploy.yml                  # GitHub Actions: preview on PR, up on merge
<!-- Note 97: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── aws/                        # ECS Fargate cluster + ALB + service
│   │   ├── index.ts
│   │   ├── Pulumi.yaml
<!-- Note 98: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   └── Pulumi.prod.yaml
│   ├── azure/                      # AKS cluster + ACR integration
│   │   ├── index.ts
<!-- Note 99: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   │   ├── Pulumi.yaml
│   │   └── Pulumi.prod.yaml
│   └── gcp/                        # GKE cluster + Artifact Registry
<!-- Note 100: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│       ├── index.ts
│       ├── Pulumi.yaml
│       └── Pulumi.prod.yaml
<!-- Note 101: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
└── gitops/                         # GitOps-based continuous delivery
    ├── argocd/
    <!-- Note 102: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    │   ├── application.yaml        # Single ArgoCD Application manifest
    │   ├── app-of-apps.yaml        # App of Apps pattern for managing multiple services
    │   └── applicationset.yaml     # ApplicationSet for auto-creating apps per environment/team
    <!-- Note 103: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    │
    └── flux/
        └── kustomization.yaml      # Flux Kustomization pointing to your overlay
<!-- Note 104: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

### Kustomize vs Helm — When to Use Which

Use **Kustomize** when you want plain YAML you can read and audit without a template engine. It's built into `kubectl` and has zero dependencies. Use **Helm** when you're distributing a chart others will install, or when your templates have significant conditional logic. The `_base/` + `_overlays/` structure in this repo works with both.

<!-- Note 105: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 🏗️ `terraform/` — Infrastructure Provisioning

Standalone Terraform configurations for provisioning the cloud infrastructure your pipelines deploy to. Each folder is a self-contained root module with `main.tf`, `variables.tf`, and `outputs.tf`.

<!-- Note 106: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
terraform/
├── azure-aks/                      # AKS cluster + VNet + ACR + Log Analytics
<!-- Note 107: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── main.tf                     # All resources: RG, VNet, ACR, AKS, monitoring
│   ├── variables.tf                # Cluster size, K8s version, networking CIDRs
│   └── outputs.tf                  # Cluster name, ACR URL, kubeconfig command
<!-- Note 108: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── aws-eks/                        # EKS cluster + VPC + ECR + IAM
│   ├── main.tf                     # VPC, subnets, NAT, IAM roles, EKS, node group
<!-- Note 109: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── variables.tf                # Region, AZs, instance type, node counts
│   └── outputs.tf                  # Cluster endpoint, ECR URL, kubeconfig command
│
<!-- Note 110: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── gcp-gke/                        # GKE cluster + VPC + Artifact Registry
│   ├── main.tf                     # VPC, subnet, NAT, GKE with Workload Identity
│   ├── variables.tf                # Project ID, region, machine type, pod/service CIDRs
<!-- Note 111: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── outputs.tf                  # Cluster name, Artifact Registry URL, gcloud command
│
├── azure-app-service/              # App Service + staging slot (no K8s)
<!-- Note 112: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── main.tf                     # App Service Plan, Web App, staging slot, App Insights
│   ├── variables.tf                # SKU, runtime stack, Docker registry config
│   └── outputs.tf                  # App URL, staging URL, managed identity
<!-- Note 113: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── aws-ecs/                        # ECS Fargate + ALB + ECR
│   ├── main.tf                     # VPC, ECS cluster, task def, ALB, autoscaling
<!-- Note 114: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── variables.tf                # CPU/memory, container port, scaling limits
│   └── outputs.tf                  # ALB URL, ECR URL, cluster/service names
│
<!-- Note 115: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── aws-lambda/                     # Lambda + API Gateway
    ├── main.tf                     # Lambda function, HTTP API Gateway, IAM, logging
    ├── variables.tf                # Runtime, handler, memory, timeout, CORS
    <!-- Note 116: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    └── outputs.tf                  # API Gateway URL, function ARN, log group
```

**Key patterns used across all Terraform configs:**
<!-- Note 117: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Pinned provider versions in `required_providers`
- `project` + `environment` naming convention on all resources
- Consistent tagging (`Project`, `Environment`, `ManagedBy`)
<!-- Note 118: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Remote state backend commented out (ready to uncomment)
- `# <-- CHANGE THIS` markers on every line you need to customise
- Container registry provisioned alongside compute (ACR, ECR, Artifact Registry)

<!-- Note 119: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 🔒 `security/` — Security Scanning

Security checks that can be dropped into any pipeline. Each file is self-contained and includes instructions for viewing results.

<!-- Note 120: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
security/
├── sast/                           # Static Application Security Testing
<!-- Note 121: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── sonarqube.yml               # SonarQube/SonarCloud — quality gates + security rules
│   ├── snyk.yml                    # Snyk — SAST + dependency vuln scan in one
│   └── semgrep.yml                 # Semgrep — fast, customisable SAST rules
<!-- Note 122: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── container-scanning/
│   ├── trivy-scan.yml              # Trivy — scans image for OS + app CVEs, outputs SARIF
<!-- Note 123: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── grype-scan.yml              # Grype (Anchore) — alternative image scanner
│
├── secret-detection/
<!-- Note 124: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── gitleaks.yml                # Gitleaks — prevents secrets being committed to git
│
└── dependency-audit/
    <!-- Note 125: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    ├── npm-audit.yml               # npm audit — fails pipeline on high/critical vulns
    ├── pip-audit.yml               # pip-audit — Python dependency vulnerability check
    └── nuget-audit.yml             # dotnet list package --vulnerable
<!-- Note 126: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

**Recommended minimum security bar for any new project:** Gitleaks on every commit, Trivy on every image build, and one SAST tool (Semgrep or Snyk) on PRs.

---

<!-- Note 127: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## ✅ `quality/` — Code Quality Configs

Linter, formatter, and test coverage configurations. Drop these into your project root.

```
<!-- Note 128: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
quality/
├── sonar-project.properties    # SonarQube project config — coverage paths, exclusions
├── .editorconfig               # Consistent whitespace across all editors and languages
<!-- Note 129: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── dotnet/
│   └── .runsettings            # Test runner settings — coverage collection, output format
<!-- Note 130: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│
├── javascript/
│   ├── .eslintrc.json          # ESLint config — extends recommended + React/TypeScript rules
<!-- Note 131: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── .prettierrc             # Prettier config — consistent code formatting
│
└── python/
    <!-- Note 132: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
    ├── pyproject.toml          # ruff (linting), black (formatting), mypy (type checking) config
    └── .flake8                 # flake8 config for teams not yet on ruff
```

<!-- Note 133: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## 🔔 `notifications/` — Pipeline Alerts

Notification snippets to paste into any pipeline. They handle both success and failure states.

<!-- Note 134: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
notifications/
├── slack-notify.yml        # Slack webhook — shows branch, commit, run link, pass/fail
<!-- Note 135: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── teams-notify.yml        # Microsoft Teams adaptive card notification
├── pagerduty-notify.yml    # PagerDuty — triggers incident on pipeline failure in prod
├── datadog-notify.yml      # Datadog — deployment event, DORA metrics, service check
<!-- Note 136: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── grafana-notify.yml      # Grafana — dashboard annotation for deployment correlation
```

**Datadog integration sends three signals per deployment:**
<!-- Note 137: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
1. **Event** — appears in Event Stream, tagged by service/env/version
2. **DORA Deployment** — feeds deployment frequency metrics in Datadog DORA dashboard
3. **Service Check** — confirms deployment health status

<!-- Note 138: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Grafana integration creates dashboard annotations** — vertical markers on time-series graphs that let you visually correlate deployments with metric changes. Supports both global annotations and targeting specific dashboards by UID.

---

## 🛠️ `scripts/` — Utility Shell Scripts

<!-- Note 139: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Standalone scripts for common pipeline tasks. POSIX-compatible unless noted.

```
scripts/
<!-- Note 140: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── tag-release.sh          # Bumps semver tag (patch/minor/major) and pushes to origin
├── k8s-rollout-check.sh    # Waits for rollout to complete, exits non-zero on timeout
├── docker-cleanup.sh       # Removes dangling images and unused volumes on CI runners
<!-- Note 141: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
└── env-checker.sh          # Validates required env vars exist before deployment starts
```

---

<!-- Note 142: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## 📚 `docs/` — Guides and Decision Records

```
docs/
<!-- Note 143: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
├── decisions/              # Architecture Decision Records (ADRs)
│   ├── ADR-001-folder-structure.md     # Why the repo is structured this way
│   ├── ADR-002-helm-vs-kustomize.md    # When to use each and why both are here
<!-- Note 144: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   └── ADR-003-gitops-strategy.md      # Why ArgoCD is the recommended CD approach
│
├── guides/
<!-- Note 145: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── secrets-management.md       # How to handle secrets: Vault, Key Vault, Secrets Manager
│   ├── branching-strategy.md       # GitFlow vs trunk-based — pros, cons, recommendations
│   ├── versioning-strategy.md      # SemVer, CalVer, build numbers — what to use when
<!-- Note 146: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
│   ├── environment-strategy.md     # dev → staging → prod promotion patterns
│   └── github-actions-oidc.md      # OIDC setup for Azure, AWS, GCP — step-by-step
│
└── diagrams/
    ├── pipeline-overview.drawio    # End-to-end pipeline architecture (editable in draw.io)
    └── deployment-flow.png         # Visual of the deploy-to-K8s flow
```

---

## 📐 File Header Standard

Every template in this repo starts with a standard header so you know exactly what you're looking at:

```yaml
# ============================================================
# TEMPLATE: GitHub Actions — .NET Build & Test
# WHEN TO USE: Any ASP.NET Core / .NET 6+ project
# PREREQUISITES: None (self-contained)
# SECRETS NEEDED: None for CI / SONAR_TOKEN for sonar-scan.yml
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: ci/github-actions/_shared/reusable-docker-build.yml
# MATURITY: Stable
# ============================================================
```

**Maturity levels:**

| Badge | Meaning |
|---|---|
| `Stable` | Used in production, tested, reviewed |
| `Beta` | Works but may have rough edges |
| `Experimental` | Proof of concept, use with caution |

---

## 🤝 Contributing

Found a bug, a better pattern, or a missing stack? Contributions are welcome.

1. Fork the repo
2. Create a branch: `feat/add-go-dockerfile` or `fix/angular-ci-cache`
3. Follow the file header standard
4. Test your template against a real project before submitting
5. Open a PR with a description of what changed and why

Please don't submit templates you haven't personally run. Untested templates erode trust in the whole library.

---

## 🗺️ Roadmap

- [x] ~~Go (Dockerfile + CI)~~
- [x] ~~Ruby on Rails (Dockerfile + CI)~~
- [x] ~~Terraform infrastructure provisioning (AKS, EKS, GKE, App Service, ECS, Lambda)~~
- [x] ~~Terraform plan/apply CI/CD pipeline templates (GitHub Actions, GitLab CI, Azure Pipelines)~~
- [x] ~~Datadog / Grafana deployment notification integrations~~
- [x] ~~AWS CodePipeline target~~
- [x] ~~GitHub Actions OIDC guide for all three major clouds~~
- [x] ~~Pulumi CD examples~~

---

## ⚠️ Important Notes

**On versions:** All tool and action versions in this repo are pinned. When you copy a file, check that the versions are still current. A pinned version that was current 6 months ago may have known CVEs today.

**On secrets:** No template in this repo hardcodes a secret. Every credential is read from environment variables or secret manager references. If you see a hardcoded credential anywhere, please open an issue immediately.

**On "production-ready":** These templates are solid starting points, not finished products. Every project has context this repo doesn't know about. Review what you copy. Understand what it does. Own it.

---

*Maintained by people who have been burned by bad pipelines enough times to write this down.*
