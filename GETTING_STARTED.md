<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Getting Started — "I need X, go to Y"

Use this guide to quickly find the right template for your scenario.

---

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Scenario Index

### 🔒 Before you commit

| Need | File |
|------|------|
| Set up local pre-commit hooks and troubleshooting | [`docs/guides/pre-commit-setup.md`](docs/guides/pre-commit-setup.md) |

### 🐳 "I need to containerize my app"

| Tech | File |
<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|------|------|
| ASP.NET Core Web API | [`docker/dotnet/Dockerfile.api`](docker/dotnet/Dockerfile.api) |
| .NET Background Worker | [`docker/dotnet/Dockerfile.worker`](docker/dotnet/Dockerfile.worker) |
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Angular (prod + nginx) | [`docker/angular/Dockerfile`](docker/angular/Dockerfile) |
| React (prod) | [`docker/react/Dockerfile`](docker/react/Dockerfile) |
| React (dev hot-reload) | [`docker/react/Dockerfile.dev`](docker/react/Dockerfile.dev) |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Flask | [`docker/python/Dockerfile.flask`](docker/python/Dockerfile.flask) |
| FastAPI | [`docker/python/Dockerfile.fastapi`](docker/python/Dockerfile.fastapi) |
| Django | [`docker/python/Dockerfile.django`](docker/python/Dockerfile.django) |
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Express.js | [`docker/node/Dockerfile.express`](docker/node/Dockerfile.express) |
| Next.js | [`docker/node/Dockerfile.nextjs`](docker/node/Dockerfile.nextjs) |
| Spring Boot | [`docker/java/Dockerfile.springboot`](docker/java/Dockerfile.springboot) |
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Learning multi-stage builds | [`docker/_base/Dockerfile.multistage`](docker/_base/Dockerfile.multistage) |
| Security-hardened container | [`docker/_base/security-hardened.Dockerfile`](docker/_base/security-hardened.Dockerfile) |

---

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 🖥️ "I need a local dev environment"

| Stack | File |
|-------|------|
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| .NET + SQL Server | [`compose/dotnet-sqlserver/docker-compose.yml`](compose/dotnet-sqlserver/docker-compose.yml) |
| Python + PostgreSQL + Redis | [`compose/python-postgres-redis/docker-compose.yml`](compose/python-postgres-redis/docker-compose.yml) |
| Microservices example | [`compose/microservices-example/docker-compose.yml`](compose/microservices-example/docker-compose.yml) |
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Annotated base template | [`compose/_templates/docker-compose.base.yml`](compose/_templates/docker-compose.base.yml) |
| Test K8s manifests locally before committing | [`local-dev/kind/setup.sh`](local-dev/kind/setup.sh) |

---

### ⚙️ "I need a CI pipeline"

<!-- Note 11: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### GitHub Actions
| Tech | Pipeline |
|------|---------|
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| .NET build + test | [`ci/github-actions/dotnet/build-test.yml`](ci/github-actions/dotnet/build-test.yml) |
| .NET + SonarQube | [`ci/github-actions/dotnet/sonar-scan.yml`](ci/github-actions/dotnet/sonar-scan.yml) |
| .NET Docker publish | [`ci/github-actions/dotnet/docker-publish.yml`](ci/github-actions/dotnet/docker-publish.yml) |
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Angular build + test | [`ci/github-actions/angular/build-test.yml`](ci/github-actions/angular/build-test.yml) |
| React build + test | [`ci/github-actions/react/build-test.yml`](ci/github-actions/react/build-test.yml) |
| Python (pytest/ruff) | [`ci/github-actions/python/build-test.yml`](ci/github-actions/python/build-test.yml) |
<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Java (Maven/Gradle) | [`ci/github-actions/java/build-test.yml`](ci/github-actions/java/build-test.yml) |

#### GitLab CI
| Tech | Pipeline |
<!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|------|---------|
| .NET | [`ci/gitlab-ci/dotnet/.gitlab-ci.yml`](ci/gitlab-ci/dotnet/.gitlab-ci.yml) |
| Python | [`ci/gitlab-ci/python/.gitlab-ci.yml`](ci/gitlab-ci/python/.gitlab-ci.yml) |

<!-- Note 16: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
#### Azure Pipelines
| Tech | Pipeline |
|------|---------|
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| .NET | [`ci/azure-pipelines/dotnet/azure-pipelines.yml`](ci/azure-pipelines/dotnet/azure-pipelines.yml) |
| Angular | [`ci/azure-pipelines/angular/azure-pipelines.yml`](ci/azure-pipelines/angular/azure-pipelines.yml) |
| Python | [`ci/azure-pipelines/python/azure-pipelines.yml`](ci/azure-pipelines/python/azure-pipelines.yml) |

<!-- Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

### 🚀 "I need to deploy to production"

| Target | File |
<!-- Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
|--------|------|
| Azure AKS (GitHub Actions) | [`cd/targets/azure-aks/github-actions-deploy.yml`](cd/targets/azure-aks/github-actions-deploy.yml) |
| AWS EKS (GitHub Actions) | [`cd/targets/aws-eks/github-actions-deploy.yml`](cd/targets/aws-eks/github-actions-deploy.yml) |
<!-- Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| GCP GKE (GitHub Actions) | [`cd/targets/gcp-gke/github-actions-deploy.yml`](cd/targets/gcp-gke/github-actions-deploy.yml) |
| Azure App Service | [`cd/targets/azure-app-service/github-actions-deploy.yml`](cd/targets/azure-app-service/github-actions-deploy.yml) |
| AWS ECS | [`cd/targets/aws-ecs/github-actions-deploy.yml`](cd/targets/aws-ecs/github-actions-deploy.yml) |
<!-- Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| AWS Lambda | [`cd/targets/aws-lambda/serverless-deploy.yml`](cd/targets/aws-lambda/serverless-deploy.yml) |
| ArgoCD GitOps | [`cd/gitops/argocd/application.yaml`](cd/gitops/argocd/application.yaml) |

---

<!-- Note 22: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 🔒 "I need security scanning"

| Need | File |
|------|------|
<!-- Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| SAST (SonarQube) | [`security/sast/sonarqube.yml`](security/sast/sonarqube.yml) |
| Container scanning (Trivy) | [`security/container-scanning/trivy-scan.yml`](security/container-scanning/trivy-scan.yml) |
| Secret detection (Gitleaks) | [`security/secret-detection/gitleaks.yml`](security/secret-detection/gitleaks.yml) |
<!-- Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Dependency audit (npm) | [`security/dependency-audit/npm-audit.yml`](security/dependency-audit/npm-audit.yml) |

---

### 📖 "I want to understand the decisions"

<!-- Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Topic | ADR |
|-------|-----|
| Why this folder structure? | [`docs/decisions/ADR-001-folder-structure.md`](docs/decisions/ADR-001-folder-structure.md) |
<!-- Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Helm vs Kustomize? | [`docs/decisions/ADR-002-helm-vs-kustomize.md`](docs/decisions/ADR-002-helm-vs-kustomize.md) |
| GitOps strategy? | [`docs/decisions/ADR-003-gitops-strategy.md`](docs/decisions/ADR-003-gitops-strategy.md) |
| Secrets management | [`docs/guides/secrets-management.md`](docs/guides/secrets-management.md) |
| Branching strategy | [`docs/guides/branching-strategy.md`](docs/guides/branching-strategy.md) |
