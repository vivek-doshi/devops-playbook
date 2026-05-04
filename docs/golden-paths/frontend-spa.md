# Golden Path — Frontend SPA

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## When to use this path

- You are building a React or Angular single-page application
- Deployment target is Azure App Service (containerised) or a CDN-backed static host
- You want CI/CD, Lighthouse quality gates, and security scanning by default

Not the right path? See:
- [kubernetes-microservice.md](kubernetes-microservice.md) — the API your SPA talks to
- [serverless-app.md](serverless-app.md) — BFF or lightweight API backend

---

## Prerequisites

```bash
bash scripts/env-checker.sh
```

Additional tools:

| Tool | Purpose |
|------|---------|
| Node.js 20+ | Local dev and build |
| Docker Desktop 4.x | Container builds |
| Azure CLI / `az` | Deploy to App Service |

---

## Flow

```
local dev → pre-commit → CI (build + lint + test + Lighthouse)
         → Docker image → security scan → push
         → deploy to App Service / CDN → smoke test → alerts
```

---

## Step 1 — Local development

```bash
# React
npm install && npm run dev

# Angular
npm install && ng serve
```

For a full stack (SPA + API + DB):

```bash
docker compose -f compose/microservices-example/docker-compose.yml up
```

---

## Step 2 — Install pre-commit hooks

```bash
make hooks
```

Config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)  
Details: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 3 — Set up the CI pipeline

Copy the appropriate workflow into `.github/workflows/`:

| Framework | Build + test | Lighthouse audit |
|-----------|-------------|-----------------|
| React | [`ci/github-actions/react/build-test.yml`](../../ci/github-actions/react/build-test.yml) | Add step below |
| Angular | [`ci/github-actions/angular/build-test.yml`](../../ci/github-actions/angular/build-test.yml) | [`ci/github-actions/angular/lighthouse-audit.yml`](../../ci/github-actions/angular/lighthouse-audit.yml) |

The build pipeline runs: `npm install` → lint → unit tests → `npm run build`.

### Add the Lighthouse quality gate

The Lighthouse audit runs against a preview deployment and fails the PR if scores drop below thresholds. For Angular, use the provided workflow. For React, add a step to your workflow:

```yaml
- name: Lighthouse audit
  uses: treosh/lighthouse-ci-action@v11
  with:
    urls: ${{ steps.deploy-preview.outputs.url }}
    budgetPath: ./lighthouse-budget.json
```

### Add security scanning

```yaml
uses: ./.github/workflows/reusable-security-scan.yml
```

Source: [`ci/github-actions/_shared/reusable-security-scan.yml`](../../ci/github-actions/_shared/reusable-security-scan.yml)

| Scan | File |
|------|------|
| Secrets | [`security/secret-detection/gitleaks.yml`](../../security/secret-detection/gitleaks.yml) |
| SAST | [`security/sast/semgrep.yml`](../../security/sast/semgrep.yml) |
| Dependency audit | [`security/dependency-audit/`](../../security/dependency-audit/) |

---

## Step 4 — Build the Docker image

SPAs are served by Nginx inside a container. Each framework ships a production-ready Dockerfile:

| Framework | Dockerfile | nginx config |
|-----------|-----------|-------------|
| React | [`docker/react/Dockerfile`](../../docker/react/Dockerfile) | [`docker/react/nginx.conf`](../../docker/react/nginx.conf) |
| Angular | [`docker/angular/Dockerfile`](../../docker/angular/Dockerfile) | [`docker/angular/nginx.conf`](../../docker/angular/nginx.conf) |

Build via the shared reusable workflow:

```yaml
uses: ./.github/workflows/reusable-docker-build.yml
with:
  image-name: my-spa
  dockerfile: docker/react/Dockerfile   # or angular
```

Source: [`ci/github-actions/_shared/reusable-docker-build.yml`](../../ci/github-actions/_shared/reusable-docker-build.yml)

The Nginx config handles:
- `try_files` for client-side routing (no 404 on deep links)
- Cache-control headers for hashed assets (`max-age=31536000`) vs `index.html` (`no-cache`)
- Security headers: `X-Frame-Options`, `X-Content-Type-Options`, `Content-Security-Policy`

---

## Step 5 — Add container security scanning

```yaml
# trivy blocks on HIGH/CRITICAL vulnerabilities
source: security/container-scanning/trivy-scan.yml
```

File: [`security/container-scanning/trivy-scan.yml`](../../security/container-scanning/trivy-scan.yml)

---

## Step 6 — Provision infrastructure

### Azure App Service

```bash
cd terraform/azure-app-service
terraform init
terraform apply
```

Provisions: App Service Plan, Web App (container), Application Insights.  
Files: [`terraform/azure-app-service/main.tf`](../../terraform/azure-app-service/main.tf) · [`variables.tf`](../../terraform/azure-app-service/variables.tf)

---

## Step 7 — Deploy

### Azure App Service (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
uses: cd/targets/azure-app-service/github-actions-deploy.yml
```

Source: [`cd/targets/azure-app-service/github-actions-deploy.yml`](../../cd/targets/azure-app-service/github-actions-deploy.yml)

The workflow:
1. Pulls the image pushed in Step 4
2. Runs `az webapp config container set` with the new SHA-tagged image
3. Runs a smoke test (HTTP 200 on `/`)
4. Notifies Slack

Authentication uses OIDC (no secrets stored in GitHub):  
Guide: [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)

---

## Step 8 — Environment promotion

| Environment | Trigger | Image tag |
|-------------|---------|-----------|
| dev | Push to `main` | Git SHA |
| staging | PR merged to `release/*` | Git SHA |
| production | Manual approval in GitHub Actions environment | Same SHA as staging |

Configure environment protection rules (required reviewers, deployment branches):  
Guide: [`ci/github-actions/_shared/environment-protection.md`](../../ci/github-actions/_shared/environment-protection.md)

---

## Step 9 — Add observability

### Application Insights (Azure)

Application Insights is provisioned with the App Service Terraform module. Add the connection string as an app setting:

```hcl
# terraform/azure-app-service/main.tf
app_settings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.main.connection_string
}
```

### Notifications

```
notifications/slack-notify.yml      ← deployment events
notifications/pagerduty-notify.yml  ← availability alerts
```

---

## Guardrails

| Rule | Enforced by |
|------|-------------|
| No secrets in source code | Gitleaks pre-commit + CI |
| No `latest` image tags | CI pipeline tags with Git SHA only |
| Security headers on Nginx | `docker/react/nginx.conf`, `docker/angular/nginx.conf` |
| Lighthouse score thresholds | `lighthouse-budget.json` in your repo root |
| OIDC only for cloud auth | [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md) |

---

## Responsibilities

| Role | Owns |
|------|------|
| Developer | Steps 1–5, Dockerfile tweaks, Lighthouse budget |
| Platform team | Step 6 (Terraform), OIDC federation, App Service config |
| Security team | CSP policy in nginx.conf, dependency audit thresholds |
