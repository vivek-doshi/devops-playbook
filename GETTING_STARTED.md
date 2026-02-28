# Getting Started — "I need X, go to Y"

Use this guide to quickly find the right template for your scenario.

---

## Scenario Index

### 🐳 "I need to containerize my app"

| Tech | File |
|------|------|
| ASP.NET Core Web API | [`docker/dotnet/Dockerfile.api`](docker/dotnet/Dockerfile.api) |
| .NET Background Worker | [`docker/dotnet/Dockerfile.worker`](docker/dotnet/Dockerfile.worker) |
| Angular (prod + nginx) | [`docker/angular/Dockerfile`](docker/angular/Dockerfile) |
| React (prod) | [`docker/react/Dockerfile`](docker/react/Dockerfile) |
| React (dev hot-reload) | [`docker/react/Dockerfile.dev`](docker/react/Dockerfile.dev) |
| Flask | [`docker/python/Dockerfile.flask`](docker/python/Dockerfile.flask) |
| FastAPI | [`docker/python/Dockerfile.fastapi`](docker/python/Dockerfile.fastapi) |
| Django | [`docker/python/Dockerfile.django`](docker/python/Dockerfile.django) |
| Express.js | [`docker/node/Dockerfile.express`](docker/node/Dockerfile.express) |
| Next.js | [`docker/node/Dockerfile.nextjs`](docker/node/Dockerfile.nextjs) |
| Spring Boot | [`docker/java/Dockerfile.springboot`](docker/java/Dockerfile.springboot) |
| Learning multi-stage builds | [`docker/_base/Dockerfile.multistage`](docker/_base/Dockerfile.multistage) |
| Security-hardened container | [`docker/_base/security-hardened.Dockerfile`](docker/_base/security-hardened.Dockerfile) |

---

### 🖥️ "I need a local dev environment"

| Stack | File |
|-------|------|
| .NET + SQL Server | [`compose/dotnet-sqlserver/docker-compose.yml`](compose/dotnet-sqlserver/docker-compose.yml) |
| Python + PostgreSQL + Redis | [`compose/python-postgres-redis/docker-compose.yml`](compose/python-postgres-redis/docker-compose.yml) |
| Microservices example | [`compose/microservices-example/docker-compose.yml`](compose/microservices-example/docker-compose.yml) |
| Annotated base template | [`compose/_templates/docker-compose.base.yml`](compose/_templates/docker-compose.base.yml) |

---

### ⚙️ "I need a CI pipeline"

#### GitHub Actions
| Tech | Pipeline |
|------|---------|
| .NET build + test | [`ci/github-actions/dotnet/build-test.yml`](ci/github-actions/dotnet/build-test.yml) |
| .NET + SonarQube | [`ci/github-actions/dotnet/sonar-scan.yml`](ci/github-actions/dotnet/sonar-scan.yml) |
| .NET Docker publish | [`ci/github-actions/dotnet/docker-publish.yml`](ci/github-actions/dotnet/docker-publish.yml) |
| Angular build + test | [`ci/github-actions/angular/build-test.yml`](ci/github-actions/angular/build-test.yml) |
| React build + test | [`ci/github-actions/react/build-test.yml`](ci/github-actions/react/build-test.yml) |
| Python (pytest/ruff) | [`ci/github-actions/python/build-test.yml`](ci/github-actions/python/build-test.yml) |
| Java (Maven/Gradle) | [`ci/github-actions/java/build-test.yml`](ci/github-actions/java/build-test.yml) |

#### GitLab CI
| Tech | Pipeline |
|------|---------|
| .NET | [`ci/gitlab-ci/dotnet/.gitlab-ci.yml`](ci/gitlab-ci/dotnet/.gitlab-ci.yml) |
| Python | [`ci/gitlab-ci/python/.gitlab-ci.yml`](ci/gitlab-ci/python/.gitlab-ci.yml) |

#### Azure Pipelines
| Tech | Pipeline |
|------|---------|
| .NET | [`ci/azure-pipelines/dotnet/azure-pipelines.yml`](ci/azure-pipelines/dotnet/azure-pipelines.yml) |
| Angular | [`ci/azure-pipelines/angular/azure-pipelines.yml`](ci/azure-pipelines/angular/azure-pipelines.yml) |
| Python | [`ci/azure-pipelines/python/azure-pipelines.yml`](ci/azure-pipelines/python/azure-pipelines.yml) |

---

### 🚀 "I need to deploy to production"

| Target | File |
|--------|------|
| Azure AKS (GitHub Actions) | [`cd/targets/azure-aks/github-actions-deploy.yml`](cd/targets/azure-aks/github-actions-deploy.yml) |
| AWS EKS (GitHub Actions) | [`cd/targets/aws-eks/github-actions-deploy.yml`](cd/targets/aws-eks/github-actions-deploy.yml) |
| GCP GKE (GitHub Actions) | [`cd/targets/gcp-gke/github-actions-deploy.yml`](cd/targets/gcp-gke/github-actions-deploy.yml) |
| Azure App Service | [`cd/targets/azure-app-service/github-actions-deploy.yml`](cd/targets/azure-app-service/github-actions-deploy.yml) |
| AWS ECS | [`cd/targets/aws-ecs/github-actions-deploy.yml`](cd/targets/aws-ecs/github-actions-deploy.yml) |
| AWS Lambda | [`cd/targets/aws-lambda/serverless-deploy.yml`](cd/targets/aws-lambda/serverless-deploy.yml) |
| ArgoCD GitOps | [`cd/gitops/argocd/application.yaml`](cd/gitops/argocd/application.yaml) |

---

### 🔒 "I need security scanning"

| Need | File |
|------|------|
| SAST (SonarQube) | [`security/sast/sonarqube.yml`](security/sast/sonarqube.yml) |
| Container scanning (Trivy) | [`security/container-scanning/trivy-scan.yml`](security/container-scanning/trivy-scan.yml) |
| Secret detection (Gitleaks) | [`security/secret-detection/gitleaks.yml`](security/secret-detection/gitleaks.yml) |
| Dependency audit (npm) | [`security/dependency-audit/npm-audit.yml`](security/dependency-audit/npm-audit.yml) |

---

### 📖 "I want to understand the decisions"

| Topic | ADR |
|-------|-----|
| Why this folder structure? | [`docs/decisions/ADR-001-folder-structure.md`](docs/decisions/ADR-001-folder-structure.md) |
| Helm vs Kustomize? | [`docs/decisions/ADR-002-helm-vs-kustomize.md`](docs/decisions/ADR-002-helm-vs-kustomize.md) |
| GitOps strategy? | [`docs/decisions/ADR-003-gitops-strategy.md`](docs/decisions/ADR-003-gitops-strategy.md) |
| Secrets management | [`docs/guides/secrets-management.md`](docs/guides/secrets-management.md) |
| Branching strategy | [`docs/guides/branching-strategy.md`](docs/guides/branching-strategy.md) |
