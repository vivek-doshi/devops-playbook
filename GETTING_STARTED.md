# Getting Started - DevOps Playbook

Use this guide when you need to move quickly from "I need X" to the right folder, template, and workflow.

## Start Local In 10 Minutes

### Option A: VS Code Dev Container (recommended)

1. Install Docker Desktop and VS Code.
2. Install the Dev Containers extension in VS Code.
3. Open this repository and run "Dev Containers: Reopen in Container".
4. Wait for the first container build to complete.
5. Run environment checks:

```bash
bash scripts/env-checker.sh
```

Use this when you want a reproducible toolchain for Terraform, Kubernetes, Helm, and security tooling without installing everything on your host machine.

Reference: [.devcontainer/README.md](.devcontainer/README.md)

### Option B: Local Host + Kind

1. Install required tools (Docker, kubectl, Helm, Kind).
2. Validate your setup with `scripts/env-checker.sh` or `scripts/env-checker.ps1`.
3. Create a local cluster:

```bash
bash local-dev/kind/setup.sh
```

Reference: [local-dev/README.md](local-dev/README.md)

## How To Use Golden Paths

Golden paths are opinionated, end-to-end workflows that connect multiple folders in this repo.

1. Choose the path that matches your use case in [docs/golden-paths/](docs/golden-paths/).
2. Follow steps in order instead of copying random files.
3. Use linked templates from `docker/`, `ci/`, `cd/`, and `terraform/`.
4. Apply guardrails from `ci-security/`, `policy/`, `secops/`, `secrets/`, `catalog/`, and `finops/`.
5. Use `observability/` and `notifications/` for operations after deployment.

Suggested first paths:
- [docs/golden-paths/platform-onboarding.md](docs/golden-paths/platform-onboarding.md)
- [docs/golden-paths/kubernetes-microservice.md](docs/golden-paths/kubernetes-microservice.md)
- [docs/golden-paths/serverless-app.md](docs/golden-paths/serverless-app.md)

## Major Components (What + How)

The table below covers major sections from `backup` through `terraform` (website intentionally excluded).

| Component | What it is | Use it alone | Use it with others |
|---|---|---|---|
| [backup/](backup/) | Backup and restore patterns for Kubernetes and managed databases | Configure Velero schedules or DB backup snippets | Pair with `cd/`, `terraform/`, and runbooks in `docs/` for full DR workflows |
| [catalog/](catalog/) | Git-native service and team ownership registry | Register service metadata and owners | Pair with `policy/`, `ci/`, and `secops/` for governance and compliance evidence |
| [cd/](cd/) | Deployment templates (Kubernetes, Helm, GitOps, cloud targets) | Deploy workloads to one target | Pair with `ci/`, `terraform/`, and `secrets/` for complete release pipelines |
| [ci/](ci/) | CI pipeline templates across platforms | Build and test code in one CI system | Pair with `ci-security/`, `cd/`, and `quality/` to enforce pre-deploy gates |
| [ci-security/](ci-security/) | Shift-left security scanning templates | Add SAST, container, secret, dependency, IaC scans to PR flow | Pair with `secops/` and `policy/` for full lifecycle security |
| [compose/](compose/) | Local multi-service Docker Compose stacks | Run app + dependencies locally | Pair with `docker/` and `local-dev/` to mirror production-like behavior |
| [docker/](docker/) | Production-focused Dockerfile templates | Containerize a single service | Pair with `ci/` for build and `cd/` for deployment |
| [docs/](docs/) | Guides, golden paths, ADRs, and runbooks | Learn one topic in isolation | Use as the control plane for how all technical folders connect |
| [finops/](finops/) | Cost governance and optimization tooling | Analyze spend and rightsizing opportunities | Pair with `policy/`, `observability/`, and `ci/` for continuous cost control |
| [local-dev/](local-dev/) | Local Kubernetes setup and helper scripts | Stand up a disposable cluster with Kind | Pair with `cd/`, `docker/`, and `observability/` for local pre-merge validation |
| [notifications/](notifications/) | Alert routing templates for Slack, Teams, PagerDuty, Datadog, Grafana | Configure one notification channel | Pair with `observability/`, `secops/`, and `finops/` alerts |
| [observability/](observability/) | Metrics, logs, traces, SLO assets | Deploy a single telemetry component | Pair with `notifications/`, `secops/`, and `docs/runbooks/` for incident operations |
| [policy/](policy/) | Policy-as-code (Kyverno and Conftest) | Enforce one policy check | Pair with `cd/`, `catalog/`, `finops/`, and `secops/` for consistent governance |
| [quality/](quality/) | Language quality baselines (lint/test/static analysis config) | Apply quality checks per language | Pair with `ci/` and `ci-security/` for shift-left quality + security |
| [scripts/](scripts/) | Utility scripts for checks, cleanup, rollout validation, release tagging | Run individual helper commands | Pair with local workflows and CI jobs for repeatable operations |
| [secops/](secops/) | Runtime security, supply-chain verification, compliance workflows | Run one control set (Falco, kube-bench, policy package) | Pair with `ci-security/`, `policy/`, `observability/`, and `notifications/` |
| [secrets/](secrets/) | Secret distribution and rotation patterns | Configure one secret backend integration | Pair with `cd/`, `ci/`, and `docs/guides/secrets-management.md` |
| [terraform/](terraform/) | IaC blueprints for cloud infrastructure | Provision one cloud target | Pair with `cd/` deploy templates and `ci/` plan/apply automation |

## Scenario Index

### I need to containerize an app
- [.NET API](docker/dotnet/Dockerfile.api)
- [React production build](docker/react/Dockerfile)
- [Python FastAPI](docker/python/Dockerfile.fastapi)
- [Node Express](docker/node/Dockerfile.express)

### I need local environments
- [Compose stacks](compose/README.md)
- [Kind cluster](local-dev/README.md)
- [Dev containers](.devcontainer/README.md)

### I need CI and security checks
- [CI templates](ci/README.md)
- [Security scan templates](ci-security/README.md)
- [Policy checks](policy/README.md)

### I need deployment templates
- [CD templates](cd/README.md)
- [Terraform IaC](terraform/README.md)
- [Secrets integration](secrets/README.md)

### I need runtime operations and governance
- [Observability stack](observability/README.md)
- [SecOps controls](secops/README.md)
- [Service catalog](catalog/README.md)
- [FinOps controls](finops/README.md)
- [Backup and DR](backup/README.md)

## Suggested Onboarding Order

1. Read [docs/guides/onboarding.md](docs/guides/onboarding.md).
2. Set up local using `.devcontainer` or `local-dev/kind`.
3. Pick one golden path and complete it end-to-end.
4. Add CI and security checks before first deployment.
5. Add observability, notifications, and runbook links before production rollout.
6. Add catalog and FinOps guardrails for day-2 governance.

## Beginner-to-Intermediate Learning Path

Use [docs/guides/devops-learning-path-intermediate.md](docs/guides/devops-learning-path-intermediate.md) for a structured skill roadmap.
