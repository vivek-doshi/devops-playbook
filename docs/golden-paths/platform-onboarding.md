# Golden Path — Platform Onboarding

> **An opinionated, end-to-end workflow that guides developers from idea → production**

---

## Who this is for

A new team joining the organisation, or an existing team adopting this playbook for the first time.

By the end of this path your team will have:

- A working local development environment
- Pre-commit hooks installed and enforced
- A GitHub repository wired to CI templates
- A named Kubernetes namespace with RBAC and network isolation
- Secrets management configured
- An on-call rotation and alert routing

This path does not build an application. It gets your team's platform foundations in place so that the application paths ([kubernetes-microservice.md](kubernetes-microservice.md), [frontend-spa.md](frontend-spa.md), etc.) work on first attempt.

---

## Prerequisites

Every engineer on the team runs this before anything else:

```bash
bash scripts/env-checker.sh
```

Required tool versions and install links: [docs/guides/onboarding.md](../guides/onboarding.md)

---

## Flow

```
local toolchain → clone + bootstrap → kind cluster → hooks
→ GitHub repo setup → namespace + RBAC → secrets store
→ observability → alert routing → choose an app path
```

---

## Step 1 — Set up individual workstations

Each engineer follows [docs/guides/onboarding.md](../guides/onboarding.md).

The key actions are:

```bash
# 1. Clone the repo
git clone https://github.com/your-org/cicd-reference.git
cd cicd-reference

# 2. Verify the toolchain
bash scripts/env-checker.sh

# 3. Install pre-commit hooks (once per clone)
make hooks
```

Pre-commit config: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml)  
What hooks do: [docs/guides/pre-commit-setup.md](../guides/pre-commit-setup.md)

---

## Step 2 — Start the shared local cluster

For local development the repo ships a `kind` cluster that mirrors the production overlay structure.

```bash
make dev
```

This runs [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh) which:

1. Creates a kind cluster named `devops-playbook`
2. Starts a local container registry at `localhost:5001`
3. Installs ingress-nginx
4. Creates a `dev` namespace

One engineer sets this up; others on the team may run it independently on their own machines.  
Config: [`local-dev/kind/kind-config.yaml`](../../local-dev/kind/kind-config.yaml)

To tear down cleanly:

```bash
bash local-dev/kind/teardown.sh
```

---

## Step 3 — Set up your GitHub repository

### Branch protection

Apply the branching strategy for your team:

- Default: [docs/guides/branching-strategy.md](../guides/branching-strategy.md) (trunk-based)
- Set `main` as protected — require PR reviews and status checks to pass

### Conventional commits

Enforce commit message format so release automation works:

```yaml
# .github/workflows/pr-conventional-commit.yml — copy this into your repo
```

Source: [`ci/github-actions/_shared/pr-conventional-commit.yml`](../../ci/github-actions/_shared/pr-conventional-commit.yml)  
Guide: [docs/guides/conventional-commits.md](../guides/conventional-commits.md)

### Release strategy

Choose one:

| Strategy | When to use | File |
|----------|-------------|------|
| Release Please | Libraries and versioned APIs | [`ci/github-actions/_strategies/release-please.yml`](../../ci/github-actions/_strategies/release-please.yml) |
| Semantic Release | Apps with continuous delivery | [`ci/github-actions/_strategies/semantic-release.yml`](../../ci/github-actions/_strategies/semantic-release.yml) |

Guide: [docs/guides/versioning-strategy.md](../guides/versioning-strategy.md)

### OIDC federation

Set up keyless authentication between GitHub Actions and your cloud. This replaces long-lived secrets stored in GitHub.

Guide: [docs/guides/github-actions-oidc.md](../guides/github-actions-oidc.md)

---

## Step 4 — Request your Kubernetes namespace

Open a PR adding your team's namespace config to:

```
cd/kubernetes/_overlays/dev/     ← dev overlay
cd/kubernetes/_overlays/staging/
cd/kubernetes/_overlays/prod/
```

The platform team will review and apply. Your namespace will include:

| Resource | File |
|----------|------|
| RBAC (developer + read-only roles) | [`cd/kubernetes/_base/rbac/`](../../cd/kubernetes/_base/rbac/) |
| Network policy (deny-all default) | [`cd/kubernetes/_base/networkpolicy.yaml`](../../cd/kubernetes/_base/networkpolicy.yaml) |
| Resource quotas | Configured per overlay |

---

## Step 5 — Configure secrets management

Choose the secrets store for your cloud:

| Cloud | Config file |
|-------|------------|
| AWS Secrets Manager | [`secrets/external-secrets/aws-secret-store.yaml`](../../secrets/external-secrets/aws-secret-store.yaml) |
| Azure Key Vault | [`secrets/external-secrets/azure-secret-store.yaml`](../../secrets/external-secrets/azure-secret-store.yaml) |
| GCP Secret Manager | [`secrets/external-secrets/gcp-secret-store.yaml`](../../secrets/external-secrets/gcp-secret-store.yaml) |

Apply the store config to your namespace. Reference template:

```
secrets/external-secrets/example-external-secret.yaml
```

Full guide: [docs/guides/secrets-management.md](../guides/secrets-management.md)

---

## Step 6 — Enforce cluster policies

The following Kyverno policies apply cluster-wide. Review them so your services are compliant from day one:

| Policy | File | What it blocks |
|--------|------|----------------|
| No `latest` tag | [`policy/kyverno/disallow-latest-tag.yaml`](../../policy/kyverno/disallow-latest-tag.yaml) | Image pull without explicit tag |
| Resource limits required | [`policy/kyverno/require-resource-limits.yaml`](../../policy/kyverno/require-resource-limits.yaml) | Pods without CPU/memory limits |
| Health probes required | [`policy/kyverno/require-liveness-readiness.yaml`](../../policy/kyverno/require-liveness-readiness.yaml) | Pods without readiness/liveness probes |
| Non-root required | [`policy/kyverno/require-non-root.yaml`](../../policy/kyverno/require-non-root.yaml) | Containers running as root |
| Read-only filesystem | [`policy/kyverno/require-readonly-filesystem.yaml`](../../policy/kyverno/require-readonly-filesystem.yaml) | Writable root filesystems |
| Labels required | [`policy/kyverno/require-labels.yaml`](../../policy/kyverno/require-labels.yaml) | Missing `app`, `version`, `team` labels |

---

## Step 7 — Wire up observability

The platform team maintains the Prometheus stack. Your team configures:

1. **Alert rules** — copy a template from [`observability/prometheus/alerts/`](../../observability/prometheus/alerts/) and adjust label selectors to match your service's `app=` label.
2. **Dashboards** — import a JSON template from [`observability/prometheus/dashboards/`](../../observability/prometheus/dashboards/) into Grafana, then edit the data sources.
3. **SLOs** — define your availability target in [`observability/prometheus/slos/`](../../observability/prometheus/slos/).

---

## Step 8 — Set up alert routing

Decide where failure alerts go:

| Channel | Config file | Use for |
|---------|------------|---------|
| Slack | [`notifications/slack-notify.yml`](../../notifications/slack-notify.yml) | Dev and staging |
| PagerDuty | [`notifications/pagerduty-notify.yml`](../../notifications/pagerduty-notify.yml) | Production on-call |
| Teams | [`notifications/teams-notify.yml`](../../notifications/teams-notify.yml) | If your team uses Teams |

Configure the receiver in Alertmanager to route alerts with your team's `team=` label to your channel.

---

## Step 9 — Write your first runbook

Before you go to production, write a runbook for your service's most likely failure modes. Use the template:

```
docs/runbooks/template.md
```

File: [`docs/runbooks/template.md`](../runbooks/template.md)

Example runbook: [`docs/runbooks/podcrashloobackoff.md`](../runbooks/podcrashloobackoff.md)

Store runbooks in `docs/runbooks/` and link them from your alert annotations.

---

## Step 10 — Choose your application path

With platform foundations in place, pick the right path for what you're building:

| What you're building | Path |
|---------------------|------|
| Backend API / microservice | [kubernetes-microservice.md](kubernetes-microservice.md) |
| React or Angular app | [frontend-spa.md](frontend-spa.md) |
| Lambda / Cloud Run function | [serverless-app.md](serverless-app.md) |
| Batch job / CronJob | [data-pipeline.md](data-pipeline.md) |

---

## Checklist — ready for production

Before any service goes to `prod`, confirm all of the following:

- [ ] Pre-commit hooks installed on all engineers' machines
- [ ] Branch protection enabled on `main`
- [ ] OIDC federation configured (no long-lived keys in GitHub secrets)
- [ ] Namespace exists with RBAC and NetworkPolicy
- [ ] External Secrets store configured and tested
- [ ] At least one alert rule deployed and tested (fire it, confirm it routes)
- [ ] PagerDuty rotation set up for the team
- [ ] Runbook written and linked from alert annotation
- [ ] Velero backup schedule applied to namespace

---

## Responsibilities

| Role | Owns |
|------|------|
| Platform team | Steps 4, 6 (namespace provisioning, Kyverno policies, Prometheus stack) |
| Team lead / tech lead | Steps 3, 8 (repo setup, alert routing), checklist sign-off |
| Every engineer | Steps 1–2 (local toolchain), Step 9 (runbook authoring) |
