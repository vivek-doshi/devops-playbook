# 🚀 CICD Reference Kit

> **A battle-tested, copy-paste-ready reference library for CI/CD pipelines, Docker configurations, and Kubernetes deployments.**
>
> Built for teams who want a solid, opinionated starting point — not another hour of Googling.

---

## Who Is This For?

| Role | How to Use This Repo |
|---|---|
| **Junior Developer** | Copy the file closest to your stack, follow the `# <-- CHANGE THIS` comments |
| **Mid-level Developer** | Use as a baseline, extend with your project's specifics |
| **Tech Lead / Architect** | Fork this repo as your org's internal standard, lock down approved patterns |
| **DevOps Engineer** | Reference for cross-platform equivalencies and deployment targets |

---

## ⚡ Quick Start — "I just need a file"

**"I need a Dockerfile for my .NET API"**
→ Go to [`docker/dotnet/Dockerfile.api`](docker/dotnet/Dockerfile.api)

**"I need a GitHub Actions pipeline that builds and tests my React app"**
→ Go to [`ci/github-actions/react/build-test.yml`](ci/github-actions/react/build-test.yml)

**"I need to deploy to AKS using Azure Pipelines"**
→ Go to [`cd/targets/azure-aks/azure-pipelines-deploy.yml`](cd/targets/azure-aks/azure-pipelines-deploy.yml)

**"I need a local dev environment with Postgres and Redis"**
→ Go to [`compose/python-postgres-redis/docker-compose.yml`](compose/python-postgres-redis/docker-compose.yml)

**"I need to add security scanning to my pipeline"**
→ Go to [`security/`](security/) and pick your scanner

---

## 📁 Repository Structure

```
cicd-reference/
├── docker/               # Dockerfiles for every major stack
├── compose/              # Docker Compose for local dev environments
├── ci/                   # CI pipeline templates (GitHub, GitLab, Azure, Jenkins)
├── cd/                   # CD pipeline templates + K8s manifests + Helm charts
├── security/             # Security scanning integrations
├── quality/              # Code quality configs (SonarQube, linters, formatters)
├── notifications/        # Slack, Teams, PagerDuty alert templates
├── scripts/              # Utility shell scripts
└── docs/                 # Guides, ADRs, diagrams
```

---

## 🐳 `docker/` — Dockerfiles

Every Dockerfile here is production-ready with multi-stage builds, non-root users, and minimal final images. Each one has comments explaining every non-obvious decision.

```
docker/
├── dotnet/
│   ├── Dockerfile.api          # ASP.NET Core Web API — multi-stage, SDK build → runtime image
│   ├── Dockerfile.worker       # .NET Background Service / Worker — no HTTP port exposed
│   └── .dockerignore           # Excludes bin/, obj/, *.user, secrets
│
├── angular/
│   ├── Dockerfile              # Multi-stage: Node build → nginx serve (production)
│   ├── nginx.conf              # Custom nginx config with gzip, security headers, SPA routing
│   └── .dockerignore           # Excludes node_modules, dist
│
├── react/
│   ├── Dockerfile              # Multi-stage: Node build → nginx serve (production)
│   ├── Dockerfile.dev          # Development only — hot reload via volume mount
│   └── nginx.conf              # nginx config tuned for React SPA routing
│
├── python/
│   ├── Dockerfile.flask        # Flask app — gunicorn as WSGI server
│   ├── Dockerfile.fastapi      # FastAPI — uvicorn with worker config
│   ├── Dockerfile.django       # Django — gunicorn, collectstatic baked in
│   └── .dockerignore           # Excludes __pycache__, .venv, *.pyc
│
├── node/
│   ├── Dockerfile.express      # Express.js API — production-hardened, non-root
│   └── Dockerfile.nextjs       # Next.js — standalone output mode for minimal image
│
├── java/
│   ├── Dockerfile.springboot   # Spring Boot — layered JAR for better cache reuse
│   └── Dockerfile.gradle       # Gradle-based build — multi-stage with Gradle cache
│
└── _base/
    ├── Dockerfile.multistage   # Heavily annotated teaching example explaining every layer
    └── security-hardened.Dockerfile  # Distroless final image, read-only FS, dropped capabilities
```

**Key patterns used across all Dockerfiles:**
- Multi-stage builds (build stage never ships to prod)
- Non-root user created and used in final stage
- `.dockerignore` provided alongside every Dockerfile
- `HEALTHCHECK` instructions included
- Pinned base image versions (no `latest` tags)

---

## 🧩 `compose/` — Local Development Environments

Docker Compose files for spinning up full local stacks. These are **dev-only** — they prioritise convenience (volume mounts, exposed ports) over security.

```
compose/
├── dotnet-sqlserver/
│   └── docker-compose.yml      # .NET API + SQL Server + Seq (structured logging UI)
│
├── python-postgres-redis/
│   └── docker-compose.yml      # Python app + PostgreSQL + Redis + pgAdmin UI
│
├── microservices-example/
│   └── docker-compose.yml      # 3-service example with shared network, API gateway pattern
│
└── _templates/
    └── docker-compose.base.yml # Template with every common pattern annotated — start here
```

**What `_templates/docker-compose.base.yml` covers:** named volumes, named networks, healthcheck dependencies (`depends_on` with condition), env file usage, service profiles for optional tools.

---

## ⚙️ `ci/` — Continuous Integration Pipelines

CI templates organised first by **platform**, then by **tech stack**. Pick your platform folder, then find your language.

### Platform Overview

| Platform | Best For | Notes |
|---|---|---|
| `github-actions/` | GitHub-hosted repos, OSS projects | Native OIDC to cloud, reusable workflows |
| `gitlab-ci/` | Self-hosted GitLab, enterprise | Powerful include/extend system |
| `azure-pipelines/` | Azure DevOps shops | Deep Azure integration, YAML templates |
| `jenkins/` | Legacy enterprise, custom infra | Groovy Jenkinsfiles, shared libraries |

```
ci/
├── github-actions/
│   ├── dotnet/
│   │   ├── build-test.yml          # Restore, build, test, publish coverage
│   │   ├── sonar-scan.yml          # SonarCloud integration with PR decoration
│   │   └── docker-publish.yml      # Build image, push to registry (GHCR or ACR)
│   │
│   ├── angular/
│   │   ├── build-test.yml          # npm ci, lint, test (Jest/Karma), build
│   │   └── lighthouse-audit.yml    # Automated Lighthouse CI score gating
│   │
│   ├── react/
│   │   └── build-test.yml          # npm ci, lint (ESLint), test, build
│   │
│   ├── python/
│   │   ├── build-test.yml          # pip install, pytest, coverage report, ruff lint
│   │   └── security-scan.yml       # bandit (SAST) + pip-audit (dependency check)
│   │
│   ├── java/
│   │   └── build-test.yml          # Maven and Gradle variants in one file using matrix
│   │
│   ├── _shared/                    # Reusable workflows (call with `uses:`)
│   │   ├── reusable-docker-build.yml   # Build + push image, outputs image digest
│   │   ├── reusable-security-scan.yml  # Trivy scan, uploads SARIF to GitHub Security tab
│   │   └── reusable-notify-slack.yml   # Success/failure Slack notification
│   │
│   └── _strategies/                # Advanced pipeline patterns
│       ├── matrix-build.yml        # Test across multiple OS / runtime versions simultaneously
│       ├── monorepo-affected.yml   # Only trigger jobs for services that actually changed
│       └── release-please.yml      # Automated changelog + version bump PRs
│
├── gitlab-ci/
│   ├── dotnet/
│   │   └── .gitlab-ci.yml          # Stages: build → test → sonar → docker → tag
│   │
│   ├── python/
│   │   └── .gitlab-ci.yml          # Stages: lint → test → security → docker
│   │
│   ├── _includes/                  # Reusable CI fragments (use with `include:`)
│   │   ├── .docker-build.yml       # Kaniko-based image build (works in rootless runners)
│   │   ├── .sast-scan.yml          # GitLab SAST template with custom rules
│   │   └── .notify.yml             # Slack/Teams notification jobs
│   │
│   └── _strategies/
│       ├── parent-child-pipeline.yml   # Trigger separate pipelines per service in a monorepo
│       └── dynamic-pipeline.yml        # Generate pipeline YAML at runtime based on changed files
│
├── azure-pipelines/
│   ├── dotnet/
│   │   └── azure-pipelines.yml     # Build, test, SonarQube, publish artifact, docker push
│   │
│   ├── angular/
│   │   └── azure-pipelines.yml     # Build, test, docker push to ACR
│   │
│   ├── python/
│   │   └── azure-pipelines.yml     # Lint, test with pytest, publish test results
│   │
│   ├── _templates/                 # Azure YAML templates (use with `extends:`)
│   │   ├── build-template.yml      # Reusable build steps parametrised by language
│   │   ├── docker-template.yml     # ACR login + build + push
│   │   └── test-template.yml       # Test run + result publishing + coverage
│   │
│   └── _strategies/
│       ├── variable-groups.yml     # Linking pipeline variables to Azure Key Vault secrets
│       └── deployment-gates.yml    # Pre/post-deployment approval gates and health checks
│
└── jenkins/
    ├── dotnet/
    │   └── Jenkinsfile             # Declarative pipeline: build → test → docker → deploy
    │
    ├── python/
    │   └── Jenkinsfile             # Declarative pipeline with virtual env and pytest
    │
    └── _shared/
        └── shared-library-example/ # Example of a Jenkins Shared Library structure (vars/, src/)
```

### What Every CI Template Includes

Every CI file in this repo covers: dependency caching, build step, unit test run, test result publishing, code coverage threshold enforcement, and image build trigger on the main branch.

---

## 🚢 `cd/` — Continuous Deployment

Deployment configs split into three concerns: **what runs on Kubernetes** (manifests), **how it's packaged** (Helm), and **where it goes** (cloud targets).

```
cd/
├── kubernetes/                     # Raw Kubernetes manifests using Kustomize
│   ├── _base/                      # The single source of truth — environment-agnostic
│   │   ├── deployment.yaml         # Deployment with resource limits, liveness/readiness probes
│   │   ├── service.yaml            # ClusterIP service (change to LoadBalancer for external)
│   │   ├── ingress.yaml            # Ingress with TLS, annotations for nginx/traefik
│   │   ├── hpa.yaml                # HorizontalPodAutoscaler — CPU and memory based
│   │   ├── configmap.yaml          # Non-secret config (env vars, config files)
│   │   └── kustomization.yaml      # Wires all the above together
│   │
│   ├── _overlays/                  # Environment-specific overrides (Kustomize patches)
│   │   ├── dev/                    # Low replicas, relaxed limits, debug logging
│   │   ├── staging/                # Production-like config, but smaller scale
│   │   └── prod/                   # Full replicas, strict limits, PodDisruptionBudget
│   │
│   └── _patterns/                  # Advanced deployment strategies
│       ├── blue-green.yaml         # Two identical environments, instant traffic switch
│       ├── canary.yaml             # Route % of traffic to new version before full rollout
│       └── init-containers.yaml    # DB migration init container pattern
│
├── helm/                           # Helm chart templates
│   ├── webapp/                     # Generic web application chart
│   │   ├── Chart.yaml              # Chart metadata — name, version, appVersion
│   │   ├── values.yaml             # All defaults documented with comments
│   │   ├── values.dev.yaml         # Dev environment overrides
│   │   ├── values.prod.yaml        # Production overrides (higher replicas, stricter limits)
│   │   └── templates/              # Kubernetes resource templates using Helm templating
│   │
│   └── microservice/               # Microservice-specific chart with sidecar support
│
├── targets/                        # Cloud-specific deployment pipeline files
│   ├── azure-aks/
│   │   ├── github-actions-deploy.yml       # OIDC auth → kubeconfig → kubectl/helm deploy
│   │   ├── gitlab-deploy.yml               # GitLab CI job deploying to AKS
│   │   └── azure-pipelines-deploy.yml      # Azure Pipelines task-based AKS deploy
│   │
│   ├── aws-eks/
│   │   ├── github-actions-deploy.yml       # OIDC auth → aws eks update-kubeconfig → deploy
│   │   └── gitlab-deploy.yml               # GitLab CI deploying to EKS with IAM role
│   │
│   ├── gcp-gke/
│   │   ├── github-actions-deploy.yml       # Workload Identity → gcloud auth → deploy
│   │   └── cloudbuild.yaml                 # Native GCP Cloud Build pipeline to GKE
│   │
│   ├── azure-app-service/                  # For teams not yet on Kubernetes
│   │   └── github-actions-deploy.yml       # Build → publish → deploy to App Service slot
│   │
│   ├── aws-ecs/
│   │   └── github-actions-deploy.yml       # Push image → update ECS task definition → deploy
│   │
│   └── aws-lambda/
│       └── serverless-deploy.yml           # Serverless Framework or SAM deploy workflow
│
└── gitops/                         # GitOps-based continuous delivery
    ├── argocd/
    │   ├── application.yaml        # Single ArgoCD Application manifest
    │   ├── app-of-apps.yaml        # App of Apps pattern for managing multiple services
    │   └── applicationset.yaml     # ApplicationSet for auto-creating apps per environment/team
    │
    └── flux/
        └── kustomization.yaml      # Flux Kustomization pointing to your overlay
```

### Kustomize vs Helm — When to Use Which

Use **Kustomize** when you want plain YAML you can read and audit without a template engine. It's built into `kubectl` and has zero dependencies. Use **Helm** when you're distributing a chart others will install, or when your templates have significant conditional logic. The `_base/` + `_overlays/` structure in this repo works with both.

---

## 🔒 `security/` — Security Scanning

Security checks that can be dropped into any pipeline. Each file is self-contained and includes instructions for viewing results.

```
security/
├── sast/                           # Static Application Security Testing
│   ├── sonarqube.yml               # SonarQube/SonarCloud — quality gates + security rules
│   ├── snyk.yml                    # Snyk — SAST + dependency vuln scan in one
│   └── semgrep.yml                 # Semgrep — fast, customisable SAST rules
│
├── container-scanning/
│   ├── trivy-scan.yml              # Trivy — scans image for OS + app CVEs, outputs SARIF
│   └── grype-scan.yml              # Grype (Anchore) — alternative image scanner
│
├── secret-detection/
│   └── gitleaks.yml                # Gitleaks — prevents secrets being committed to git
│
└── dependency-audit/
    ├── npm-audit.yml               # npm audit — fails pipeline on high/critical vulns
    ├── pip-audit.yml               # pip-audit — Python dependency vulnerability check
    └── nuget-audit.yml             # dotnet list package --vulnerable
```

**Recommended minimum security bar for any new project:** Gitleaks on every commit, Trivy on every image build, and one SAST tool (Semgrep or Snyk) on PRs.

---

## ✅ `quality/` — Code Quality Configs

Linter, formatter, and test coverage configurations. Drop these into your project root.

```
quality/
├── sonar-project.properties    # SonarQube project config — coverage paths, exclusions
├── .editorconfig               # Consistent whitespace across all editors and languages
│
├── dotnet/
│   └── .runsettings            # Test runner settings — coverage collection, output format
│
├── javascript/
│   ├── .eslintrc.json          # ESLint config — extends recommended + React/TypeScript rules
│   └── .prettierrc             # Prettier config — consistent code formatting
│
└── python/
    ├── pyproject.toml          # ruff (linting), black (formatting), mypy (type checking) config
    └── .flake8                 # flake8 config for teams not yet on ruff
```

---

## 🔔 `notifications/` — Pipeline Alerts

Notification snippets to paste into any pipeline. They handle both success and failure states.

```
notifications/
├── slack-notify.yml        # Slack webhook — shows branch, commit, run link, pass/fail
├── teams-notify.yml        # Microsoft Teams adaptive card notification
└── pagerduty-notify.yml    # PagerDuty — triggers incident on pipeline failure in prod
```

---

## 🛠️ `scripts/` — Utility Shell Scripts

Standalone scripts for common pipeline tasks. POSIX-compatible unless noted.

```
scripts/
├── tag-release.sh          # Bumps semver tag (patch/minor/major) and pushes to origin
├── k8s-rollout-check.sh    # Waits for rollout to complete, exits non-zero on timeout
├── docker-cleanup.sh       # Removes dangling images and unused volumes on CI runners
└── env-checker.sh          # Validates required env vars exist before deployment starts
```

---

## 📚 `docs/` — Guides and Decision Records

```
docs/
├── decisions/              # Architecture Decision Records (ADRs)
│   ├── ADR-001-folder-structure.md     # Why the repo is structured this way
│   ├── ADR-002-helm-vs-kustomize.md    # When to use each and why both are here
│   └── ADR-003-gitops-strategy.md      # Why ArgoCD is the recommended CD approach
│
├── guides/
│   ├── secrets-management.md       # How to handle secrets: Vault, Key Vault, Secrets Manager
│   ├── branching-strategy.md       # GitFlow vs trunk-based — pros, cons, recommendations
│   ├── versioning-strategy.md      # SemVer, CalVer, build numbers — what to use when
│   └── environment-strategy.md     # dev → staging → prod promotion patterns
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

- [ ] Go (Dockerfile + CI)
- [ ] Ruby on Rails (Dockerfile + CI)
- [ ] Terraform plan/apply pipeline templates
- [ ] Pulumi CD examples
- [ ] AWS CodePipeline target
- [ ] Datadog / Grafana deployment notification integrations
- [ ] GitHub Actions OIDC guide for all three major clouds

---

## ⚠️ Important Notes

**On versions:** All tool and action versions in this repo are pinned. When you copy a file, check that the versions are still current. A pinned version that was current 6 months ago may have known CVEs today.

**On secrets:** No template in this repo hardcodes a secret. Every credential is read from environment variables or secret manager references. If you see a hardcoded credential anywhere, please open an issue immediately.

**On "production-ready":** These templates are solid starting points, not finished products. Every project has context this repo doesn't know about. Review what you copy. Understand what it does. Own it.

---

*Maintained by people who have been burned by bad pipelines enough times to write this down.*
