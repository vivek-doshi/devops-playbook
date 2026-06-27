# DevOps Learning Path (Beginner to Intermediate)

Audience: developers with programming experience and basic CI/CD familiarity who want practical DevOps depth.

## Outcome

By the end of this path, you should be able to design, implement, and operate a secure CI/CD workflow with infrastructure provisioning, observability, policy controls, and cost-awareness.

## How To Use This Path

- Work in order from foundation to operations.
- Complete one practical artifact per module.
- Use this repository's templates to build real output, not notes-only learning.

## Stage 1 - Core Platform Foundations (2-3 weeks)

### Skills to learn

- Linux and shell fundamentals
- Git workflows and branch hygiene
- Networking basics (DNS, TLS, HTTP, load balancing)
- Container fundamentals with Docker

### Practice tasks in this repository

- Run `scripts/env-checker.sh` and fix missing prerequisites.
- Build one image from `docker/` for your preferred stack.
- Launch one compose stack from `compose/`.
- Read `docs/guides/onboarding.md` and complete the local setup.

### Success criteria

- You can containerize an app and run it locally with dependencies.

## Stage 2 - CI and Code Quality (2-3 weeks)

### Skills to learn

- Pipeline design (build, test, artifact stages)
- Test strategy basics (unit, integration, smoke)
- Static quality gates and code scanning
- Artifact versioning and release tagging

### Practice tasks in this repository

- Pick one template from `ci/` and run equivalent checks in your project.
- Apply baseline settings from `quality/`.
- Add security checks from `ci-security/`.
- Use `scripts/tag-release.sh` in a mock release flow.

### Success criteria

- You can build a PR pipeline with mandatory quality and security checks.

## Stage 3 - Infrastructure and Deployment (3-4 weeks)

### Skills to learn

- Infrastructure as code fundamentals with Terraform
- Kubernetes workload and service basics
- Deployment strategies (rolling, blue/green, canary)
- GitOps and configuration layering

### Practice tasks in this repository

- Provision a sandbox target from `terraform/`.
- Deploy manifests or chart from `cd/kubernetes/` or `cd/helm/`.
- Explore `cd/gitops/` and `cd/targets/` deployment patterns.
- Validate locally with `local-dev/` Kind workflows.

### Success criteria

- You can provision infrastructure and ship one service using repeatable CD templates.

## Stage 4 - Security, Policy, and Secrets (2-3 weeks)

### Skills to learn

- Threat modeling for delivery pipelines
- Shift-left and runtime security controls
- Policy-as-code for preventive governance
- Secret lifecycle and rotation

### Practice tasks in this repository

- Add scanning templates from `ci-security/`.
- Apply policy checks from `policy/`.
- Explore runtime controls in `secops/`.
- Configure secret patterns from `secrets/` and read lifecycle guidance.

### Success criteria

- You can enforce secure defaults from PR validation through runtime admission and response.

## Stage 5 - Reliability, Operations, and FinOps (3-4 weeks)

### Skills to learn

- Observability pillars: metrics, logs, traces
- SLOs and alerting fundamentals
- Incident response and runbook design
- Cost governance and optimization loops

### Practice tasks in this repository

- Deploy or review assets in `observability/`.
- Connect alerts using `notifications/`.
- Read and exercise runbooks in `docs/runbooks/`.
- Follow the FinOps workflow in `finops/`.
- Register a service in `catalog/` and validate ownership metadata.

### Success criteria

- You can operate a service with SLO-aware alerting, incident workflows, ownership metadata, and cost controls.

## Stage 6 - Integration Capstone (2 weeks)

Build a complete flow for one service:

1. Containerize with `docker/`.
2. Add CI with `ci/` and `quality/`.
3. Add scans with `ci-security/`.
4. Provision infrastructure with `terraform/`.
5. Deploy with `cd/`.
6. Add secrets via `secrets/`.
7. Add policy checks via `policy/`.
8. Add observability and notifications.
9. Add runtime security controls from `secops/`.
10. Register ownership in `catalog/`.
11. Add backup and DR controls from `backup/`.
12. Add FinOps checks from `finops/`.

## Weekly Study Pattern (suggested)

- Weekdays: 60-90 minutes focused learning and implementation.
- Weekend: 2-3 hour integration lab and retrospective notes.
- End of each week: list what failed, what was fixed, and what to automate next.

## What to Learn Next (post-intermediate)

1. Platform engineering and internal developer platforms.
2. Advanced Kubernetes security and multi-cluster policy management.
3. SRE reliability engineering and error budget governance.
4. Cloud economics and commitment strategy optimization.
