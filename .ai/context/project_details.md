# CICD Reference Repository Brief

## What This Repository Is

This repository is a production-oriented DevOps playbook and starter kit for cloud-native teams.
It provides copy-ready templates, policy guardrails, golden paths, and operational runbooks that teams can adapt without losing baseline governance.

## Current Focus Areas

- Multi-cloud delivery patterns (AWS, Azure, GCP) for CI/CD, Kubernetes, and serverless.
- Policy-first operations with Kyverno enforcement and compliance mapping.
- Reliability engineering with SLO definitions, recording rules, burn-rate alerts, and runbooks.
- FinOps optimization loop from recommendation to merged change and savings verification.
- Git-native service catalog for ownership, on-call routing, and deployment governance.

## Documentation And Decision Baseline (Latest)

- ADR set expanded to include policy-layering and SLO-operations standards:
	- `docs/decisions/ADR-004-policy-enforcement-layering.md`
	- `docs/decisions/ADR-005-slo-driven-operations-standard.md`
- ADR index and lifecycle reference added:
	- `docs/decisions/README.md`
- Runbook catalog and authoring standard added:
	- `docs/runbooks/README.md`
- Diagram inventory and maintenance guidance added:
	- `docs/diagrams/README.md`
- Guides refreshed for consistency and repository alignment:
	- `docs/guides/branching-strategy.md`
	- `docs/guides/environment-strategy.md`
	- `docs/guides/github-actions-oidc.md`
	- `docs/guides/secrets-management.md`
	- `docs/guides/versioning-strategy.md`
	- `docs/guides/concepts.md`
	- `docs/guides/devops-learning-path-intermediate.md`

## Onboarding And Navigation Surfaces

- `GETTING_STARTED.md` is the scenario-first index that maps needs to templates, major components, and integration flow.
- Top-level component README coverage is standardized for `backup/`, `catalog/`, `cd/`, `ci/`, `ci-security/`, `compose/`, `docker/`, `docs/`, `finops/`, `local-dev/`, `notifications/`, `observability/`, `policy/`, `quality/`, `scripts/`, `secops/`, `secrets/`, and `terraform/`.
- `docs/guides/devops-learning-path-intermediate.md` provides a staged beginner-to-intermediate DevOps learning plan for engineers with programming and basic CI/CD experience.

## Target Audience

- Developers needing ready-to-use pipeline and deployment templates.
- Platform and DevOps engineers standardizing delivery patterns.
- SRE teams operating alerts, SLOs, and incident response.
- Security and compliance teams validating policy/control coverage.
- Engineering leadership driving reusable platform baselines.

## Key Repository Domains

- `docker/`, `compose/`, `local-dev/`: build and local runtime foundations.
- `ci/`: CI templates across GitHub Actions, Azure Pipelines, GitLab CI, Jenkins.
- `cd/`: Kubernetes base/overlays, GitOps, Helm, and deployment targets.
- `terraform/`, `cd/pulumi/`: infrastructure as code blueprints.
- `ci-security/`, `secops/`, `policy/`, `secrets/`: security scanning, runtime controls, policy, and secret lifecycle.
- `observability/`, `notifications/`: metrics, logs, traces, dashboards, and routing.
- `finops/`: budget governance, rightsizing, normalization, reserved-capacity analysis.
- `catalog/`: team and service registration, ownership metadata, validation tooling.
- `docs/`: golden paths, guides, runbooks, and architectural decision records.

## Suggested Navigation

1. Start with `docs/golden-paths/` (kubernetes, incident, finops optimization, SLO-driven development, service catalog).
2. Implement templates from `ci/`, `cd/`, `docker/`, `terraform/`.
3. Apply guardrails from `policy/`, `secops/`, `ci-security/`, `finops/`, and `catalog/`.
4. Operate using `observability/`, `notifications/`, and `docs/runbooks/`.
