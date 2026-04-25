# GitHub Actions — Environment Protection Rules

## What is a GitHub Environment?

A GitHub Environment is a named deployment target you configure in **Settings → Environments**.
Workflows reference it with `environment: <name>`, which makes the job pause and wait for the
protection rules to be satisfied before it runs.

The **key value**: your `secrets.PROD_DB_PASSWORD` in a job that references `environment: production`
is only available if all protection gates pass. Secrets are scoped to the environment, not the repo.

---

## How to configure (one-time, per repo)

1. Go to **Settings → Environments → New environment**
2. Name it to match exactly what workflows use (`production`, `staging`, etc.)
3. Configure protection rules:

| Rule | What it does | Recommended setting |
|------|-------------|---------------------|
| **Required reviewers** | Pause until N people approve the deployment | 1–2 (prod), 0 (dev/staging) |
| **Wait timer** | Delay start N minutes after approval | 0–5 min (gives you time to cancel) |
| **Deployment branches** | Which branches can deploy to this env | `main` only for production |
| **Deployment tags** | Which tag patterns can deploy | `v*` for prod release tags |
| **Prevent self-review** | Reviewer cannot be the same person who triggered | Enable on production |

---

## Recommended environment matrix

```
┌─────────────┬──────────────┬───────────┬─────────────────────────┐
│ Environment │ Branch/Tag   │ Reviewers │ Notes                   │
├─────────────┼──────────────┼───────────┼─────────────────────────┤
│ development │ Any          │ 0         │ Auto-deploy on PR        │
│ staging     │ main         │ 0         │ Auto-deploy after merge  │
│ production  │ main / v*.*  │ 1–2       │ Manual approval required │
│ dr-failover │ main         │ 2         │ Ops team only            │
└─────────────┴──────────────┴───────────┴─────────────────────────┘
```

---

## Workflow template with environment gate

See the example below. The `environment:` key on a job is all that is needed in the YAML —
the protection rules are enforced server-side by GitHub.

```yaml
# ============================================================
# TEMPLATE: GitHub Actions — Staged deployment with environment gates
# WHEN TO USE: Any workflow that deploys to staging and production
# PREREQUISITES: Environments configured in Settings → Environments
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: ci/github-actions/_strategies/matrix-build.yml
# MATURITY: Stable
# ============================================================

name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:           # allow manual trigger with environment selection
    inputs:
      target:
        description: "Target environment"
        required: true
        default: staging
        type: choice
        options: [staging, production]

jobs:
  # ── Build once, deploy everywhere ─────────────────────────────────
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      image-tag:    ${{ steps.meta.outputs.version }}
    steps:
      - uses: actions/checkout@v4

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}    # <-- CHANGE THIS
          tags: |
            type=sha,prefix=sha-
            type=semver,pattern={{version}}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to:   type=gha,mode=max

  # ── Deploy to staging (no approval required) ──────────────────────
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging           # <-- matches environment name in Settings → Environments
    concurrency:
      group: staging-deploy
      cancel-in-progress: false    # never cancel an in-flight deployment

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to staging
        run: |
          echo "Deploying ${{ needs.build.outputs.image-tag }} to staging"
          # kubectl set image ... or helm upgrade ...   # <-- CHANGE THIS

  # ── Deploy to production (requires approval) ──────────────────────
  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest

    # Note 1: The 'environment' key is what connects this job to the protection rules
    # configured in Settings → Environments. GitHub will pause the job here and
    # notify required reviewers before releasing the job to run.
    environment:
      name: production
      url: https://app.example.com   # <-- CHANGE THIS: shown in the deployment summary

    concurrency:
      group: production-deploy
      cancel-in-progress: false      # NEVER cancel in-progress production deploys

    permissions:
      contents: read
      id-token: write                # needed if using OIDC to cloud

    steps:
      - uses: actions/checkout@v4

      # Note 2: Secrets scoped to the 'production' environment are ONLY available
      # inside a job that references environment: production. They are not accessible
      # to any other job, including deploy-staging.
      - name: Authenticate to cloud
        run: |
          echo "Using OIDC token to authenticate"
          # aws configure or az login --federated-token   # <-- CHANGE THIS

      - name: Deploy to production
        run: |
          echo "Deploying ${{ needs.build.outputs.image-tag }} to production"
          # kubectl set image ... or helm upgrade ...   # <-- CHANGE THIS

      - name: Notify on success
        if: success()
        uses: ./.github/workflows/notify-slack.yml    # <-- CHANGE THIS or remove
```

---

## Protecting secrets per environment

1. In **Settings → Environments → production**, add secrets (e.g. `KUBECONFIG`, `PROD_DB_URL`).
2. These secrets are NOT available to jobs targeting other environments.
3. Repository secrets are available everywhere — only use them for non-sensitive values.

```
Hierarchy (most to least restricted):
  Environment secrets   → only in jobs with matching environment:
  Repository secrets    → any job in any workflow
  Organization secrets  → any repo in the org (if policy allows)
```

---

## API / Terraform equivalent (for IaC teams)

GitHub Environments can be managed via the REST API or third-party Terraform providers.
The `github` Terraform provider supports `github_repository_environment` and
`github_repository_environment_deployment_policy` resources for GitOps-style environment config.

```hcl
resource "github_repository_environment" "production" {
  repository  = "my-repo"              # <-- CHANGE THIS
  environment = "production"

  reviewers {
    teams = [data.github_team.ops.id]  # <-- CHANGE THIS
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}
```

---

## Related files

- `ci/github-actions/_strategies/release-please.yml` — triggers deployment after a release tag
- `ci/github-actions/_shared/reusable-docker-build.yml` — build step called from the deploy workflow
- `docs/decisions/` — record your environment topology as an ADR
