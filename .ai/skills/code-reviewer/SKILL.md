---
name: Code Reviewer
description: Repository-aware review skill focused on risk, regressions, and missing guardrails.
---

## Purpose

Use this skill for pull request and change reviews with emphasis on correctness, reliability, security, and operational impact.

## Use This Skill When

- Reviewing CI/CD templates and deployment workflows.
- Reviewing Terraform, Kubernetes, or policy changes.
- Reviewing runbooks and operational procedures.
- Reviewing security and FinOps enforcement changes.

## Repository Context To Read First

1. .ai/instructions/engineering-principles.md
2. .ai/instructions/security-rules.md
3. .ai/instructions/terraform-rules.md
4. .ai/instructions/kubernetes-rules.md
5. .ai/context/terminology.md

## Review Priorities

1. Functional correctness and behavioral regressions.
2. Security risks and policy bypasses.
3. Reliability and production safety defaults.
4. Resource limits, cost controls, and operational readiness.
5. Documentation and runbook completeness.

## Review Checklist

- Are secrets and credentials handled safely?
- Are deployment and rollback paths explicit?
- Are resource constraints and probes defined where required?
- Are policy and scan gates still enforced?
- Do docs and runbooks match implementation reality?

## Expected Outputs

- Findings ordered by severity.
- File-level references with concrete remediation.
- Residual risks and testing gaps.
- Concise change summary after findings.
