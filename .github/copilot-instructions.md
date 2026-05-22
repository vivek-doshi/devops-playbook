# Copilot Instructions For This Repository

## Primary AI Context

Use .ai as the canonical context root for all agent behavior in this repository.

Read in this order before making recommendations or edits:

1. .ai/instructions/engineering-principles.md
2. .ai/instructions/coding-standards.md
3. Domain-specific rules in .ai/instructions/
4. Repository context in .ai/context/
5. Retrieval routing in .ai/retrieval/

If guidance conflicts, follow this precedence:

1. engineering-principles.md
2. security-rules.md
3. domain rules (terraform-rules, kubernetes-rules, documentation-rules)
4. retrieval guidance

## Skill Catalog Under .ai/skills

Use the following skills based on intent:

- Senior DevOps Architect: .ai/skills/senior-devops-architect/SKILL.md
- Review and Refactor: .ai/skills/review-and-refactor/SKILL.md
- Code Reviewer: .ai/skills/code-reviewer/SKILL.md
- Educational Comments: .ai/skills/educational-comments/SKILL.md

## How Agents Should Operate

- Start with canonical retrieval files in .ai/retrieval/.
- Route by task intent before opening deep implementation files.
- Prefer golden paths and architecture guide over ad hoc patterns.
- For production-impacting tasks, include security, policy, and finops guardrails.
- Keep edits minimal, explicit, and aligned to established templates.

## Session Summary Requirement

- At the end of every completed session, create a session summary file.
- Store session summaries in .ai/session/.
- Use this naming convention: YYYY-MM-DD-topic.md.
- When required, refer to prior session summaries in .ai/session/ to preserve continuity.

## Review Mode Expectations

When asked to review, prioritize:

1. Bugs and regressions
2. Security and policy bypass risks
3. Reliability and operational safety
4. Missing resource limits and cost controls
5. Missing tests and documentation updates

Report findings first, ordered by severity, with concrete file-level remediation.

## Authoring And Refactoring Expectations

- Prefer reusable templates over one-off implementations.
- Avoid hardcoded environment values.
- Use descriptive names that include scope and target.
- Preserve behavior unless change is explicitly requested.
- Update relevant docs when behavior or usage changes.

## Quick Task Routing

- Architecture decisions: Senior DevOps Architect
- Cleanup and consistency improvements: Review and Refactor
- PR and change risk assessment: Code Reviewer
- Learning-focused template annotation: Educational Comments
