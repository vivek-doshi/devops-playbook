---
name: Educational Comments
description: Add concise, high-value instructional comments to templates and scripts for onboarding and learning.
---

## Purpose

Use this skill to add educational comments that teach intent and safe usage, especially in templates used by newer team members.

## Use This Skill When

- Improving onboarding clarity in CI/CD, IaC, or Kubernetes templates.
- Explaining non-obvious guardrails or production settings.
- Adding usage hints to configurable sections.
- Clarifying why a specific operational or security control exists.

## Repository Context To Read First

1. .ai/instructions/documentation-rules.md
2. .ai/context/glossary.md
3. GETTING_STARTED.md
4. docs/golden-paths/
5. scripts/add-educational-comments.ps1

## Commenting Rules

- Prefer short intent-focused comments over verbose narration.
- Explain why and when, not only what.
- Do not add noise to obvious code lines.
- Keep comments aligned with current behavior.
- Avoid exposing secrets or sensitive operational details.

## Expected Outputs

- Updated files with concise educational comments.
- Summary of key concepts introduced.
- Any sections intentionally left uncommented and why.
