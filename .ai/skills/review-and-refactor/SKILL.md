---
name: Review and Refactor
description: Improve maintainability and consistency of templates, scripts, and docs while preserving behavior.
---

## Purpose

Use this skill for safe refactoring and quality improvement in this repository without changing intended behavior.

## Use This Skill When

- Reducing duplication in CI/CD, Terraform, Kubernetes, or docs assets.
- Standardizing naming, structure, and file conventions.
- Improving readability and maintainability of templates.
- Aligning existing files to .ai/instructions standards.

## Repository Context To Read First

1. .ai/instructions/coding-standards.md
2. .ai/instructions/documentation-rules.md
3. .ai/instructions/terraform-rules.md
4. .ai/instructions/kubernetes-rules.md
5. .ai/retrieval/retrieval-rules.md

## Refactor Guardrails

- Preserve existing public template behavior unless explicitly requested.
- Keep changes minimal and scoped to the task.
- Do not remove guardrail logic from security, policy, or finops controls.
- Prefer extracting reusable patterns into existing shared locations.
- Update documentation when behavior or usage changes.

## Expected Outputs

- Refactor summary with before/after intent.
- List of changed files and why each changed.
- Validation notes (lint/build/tests where applicable).
- Follow-up opportunities that were intentionally deferred.
