# CI Pipeline Templates

This folder contains CI templates across supported platforms and tech stacks.

## Purpose

Use `ci/` to standardize build, test, lint, and artifact workflows before deployment.

## What's Inside

- `github-actions/`: GitHub Actions workflows and shared components.
- `gitlab-ci/`: GitLab CI pipelines and include templates.
- `azure-pipelines/`: Azure Pipeline templates.
- `jenkins/`: Jenkins declarative pipeline examples.

## Use This Component Alone

- Run build and test for one repository using one CI platform.
- Establish baseline CI quality gates quickly.

## Use This Component With Others

- With `quality/`: Apply language quality baselines.
- With `ci-security/`: Add shift-left security scanning.
- With `cd/`: Promote artifacts to deployment workflows.
- With `terraform/`: Add plan/apply automation.
- With `catalog/`: Validate ownership metadata at PR time.

## Typical Pipeline Order

1. Checkout and dependency restore.
2. Lint and test.
3. Security scanning.
4. Build and publish artifact.
5. Trigger deployment stage or handoff.
