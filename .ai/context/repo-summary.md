# Repository Summary

## What This Repository Fundamentally Is

This repository is a production-oriented DevOps reference playbook and starter kit.
It provides reusable templates, guardrails, and runbooks for building, securing, deploying, and operating cloud-native workloads across multiple clouds and delivery platforms.

## Core Capabilities

- Container build templates for major language stacks in docker/.
- Local development stacks in compose/ and local-dev/.
- CI templates across GitHub Actions, Azure Pipelines, GitLab CI, and Jenkins in ci/.
- CD targets, GitOps, Helm, and Kubernetes deployment patterns in cd/.
- Infrastructure as code examples and modules in terraform/ and cd/pulumi/.
- Security, policy, secrets, and compliance controls in ci-security/, secops/, policy/, and secrets/.
- Observability and alerting baseline in observability/ and notifications/.
- FinOps governance and optimization automation integrated into platform and CI/CD workflows in finops/.
- Reliability engineering assets (SLO schema, recording rules, burn-rate alerts, runbooks) in observability/ and docs/.
- Git-native service ownership catalog with validation and policy guardrails in catalog/.

## How Teams Use It

- Start from a golden path in docs/golden-paths/.
- Select templates by stack and deployment target.
- Apply security, reliability, ownership, and cost guardrails from the start.
- Adapt for organization-specific standards while preserving baseline controls.

## Recently Added Platform Capabilities

- FinOps optimization loop artifacts and decision path:
	- `finops/scripts/generate-optimization-pr.py`
	- `finops/scripts/normalize-cloud-costs.py`
	- `finops/scripts/reserved-capacity-advisor.py`
	- `docs/golden-paths/finops-optimization.md`
- SLO-driven development assets:
	- `observability/prometheus/slos/slo-schema.yaml`
	- `observability/prometheus/recording-rules/slo-burn-rates.yaml`
	- `observability/prometheus/alerts/slo-burn-rate-alerts.yaml`
	- `docs/golden-paths/slo-driven-development.md`
- Service catalog and governance:
	- `catalog/` (service and team registration)
	- `.github/workflows/validate-catalog.yml`
	- `policy/kyverno/require-catalog-registration.yaml`

## Recently Updated Documentation And ADR Coverage

- ADR updates and expansion:
	- `docs/decisions/ADR-001-folder-structure.md`
	- `docs/decisions/ADR-002-helm-vs-kustomize.md`
	- `docs/decisions/ADR-003-gitops-strategy.md`
	- `docs/decisions/ADR-004-policy-enforcement-layering.md`
	- `docs/decisions/ADR-005-slo-driven-operations-standard.md`
	- `docs/decisions/README.md`
- Guide normalization and refresh:
	- `docs/guides/branching-strategy.md`
	- `docs/guides/environment-strategy.md`
	- `docs/guides/github-actions-oidc.md`
	- `docs/guides/secrets-management.md`
	- `docs/guides/versioning-strategy.md`
	- `docs/guides/concepts.md`
	- `docs/guides/conventional-commits.md`
	- `docs/guides/onboarding.md`
	- `docs/guides/devops-learning-path-intermediate.md`
- Runbook and diagram indexes:
	- `docs/runbooks/README.md`
	- `docs/diagrams/README.md`

## Onboarding And Component Documentation Baseline

- `GETTING_STARTED.md` now serves as the primary scenario-to-template router and includes local setup, dev container guidance, major component intent, and golden path usage.
- Top-level README coverage is maintained for all major platform components from `backup/` through `terraform/` (excluding `website/`), with purpose, standalone usage, and cross-component integration guidance.
