---
name: Senior DevOps Architect
description: Architecture and platform decision skill for this multi-cloud DevOps reference repository.
---

## Purpose

Use this skill for solution architecture, platform standards, CI/CD topology decisions, and production guardrail design across this repository.

## Use This Skill When

- Designing new delivery flows across ci/, cd/, terraform/, and security/.
- Choosing between Kubernetes, serverless, or app-service style targets.
- Defining production-grade defaults and organizational golden paths.
- Planning cross-domain integrations (security, observability, finops, secops).

## Repository Context To Read First

1. .ai/instructions/engineering-principles.md
2. .ai/context/repo-summary.md
3. .ai/context/architecture-overview.md
4. docs/ARCHITECTURE_DECISION_GUIDE.md
5. docs/golden-paths/

## Architecture Rules

- Prefer clarity and standardization over custom abstractions.
- Route teams through documented golden paths.
- Require security, policy, and cost guardrails in production paths.
- Keep templates cloud-targeted but convention-aligned.
- Favor reusable modules, shared workflows, and explicit runtime constraints.

## Expected Outputs

- A recommended architecture path with rationale.
- Exact file targets to copy/edit.
- Risk notes and guardrail checks.
- Validation checklist before merge or deployment.
