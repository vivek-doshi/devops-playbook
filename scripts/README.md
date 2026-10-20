# Utility Scripts

This folder contains operational helper scripts for environment checks, rollout validation, cleanup, and release tagging.

## Purpose

Use `scripts/` for repeatable local and CI automation that does not belong to one product-specific pipeline.

## What's Inside

- Environment validation: `env-checker.sh`
- Kubernetes rollout checks: `k8s-rollout-check.sh`
- Docker cleanup: `docker-cleanup.sh`
- Release tagging: `tag-release.sh`
- Local repo quality gate: `repo-quality-local.sh`

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
