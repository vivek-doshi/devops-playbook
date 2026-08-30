# Utility Scripts

This folder contains operational helper scripts for environment checks, rollout validation, cleanup, and release tagging.

## Purpose

Use `scripts/` for repeatable local and CI automation that does not belong to one product-specific pipeline.

## What's Inside

- Environment validation: `env-checker.sh`, `env-checker.ps1`
- Kubernetes rollout checks: `k8s-rollout-check.sh`, `k8s-rollout-check.ps1`
- Docker cleanup: `docker-cleanup.sh`, `docker-cleanup.ps1`
- Release tagging: `tag-release.sh`, `tag-release.ps1`
- Local repo quality gate: `repo-quality-local.sh`, `repo-quality-local.ps1`
- Repo maintenance helpers: `generate-repo-map.ps1`, comment maintenance scripts

## Use This Component Alone

- Verify tooling before onboarding.
- Validate deployment health from a local workstation.

## Use This Component With Others

- With `local-dev/`: Preflight local cluster setup.
- With `ci/` and `cd/`: Reuse rollout and release validation in pipeline jobs.
- With `.ai/context/`: Keep repository map and context artifacts current.

## Example Commands

```bash
bash scripts/env-checker.sh
bash scripts/k8s-rollout-check.sh <namespace> <deployment>
bash scripts/tag-release.sh v1.2.3
bash scripts/repo-quality-local.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts/env-checker.ps1
powershell -ExecutionPolicy Bypass -File scripts/k8s-rollout-check.ps1 -Namespace dev -Deployment app
powershell -ExecutionPolicy Bypass -File scripts/tag-release.ps1 -Tag v1.2.3
powershell -ExecutionPolicy Bypass -File scripts/repo-quality-local.ps1
```
