# Documentation Rules

Documentation standards for guides, templates, runbooks, and architecture references.

## Writing Principles

- Prefer clear, direct language over broad conceptual text.
- Explain what to do, when to do it, and where to find the file.
- Keep examples realistic and production-aware.
- Use consistent terminology across docs and templates.

## Structure Standards

- Start with purpose and scope.
- Provide prerequisites before implementation steps.
- Include validation steps and expected outcomes.
- Include rollback or failure handling for operational procedures.
- Link to related guides, runbooks, and templates.

## Repository Documentation Expectations

- Golden paths must reference concrete file paths in this repository.
- Runbooks must include detection, immediate actions, investigation, remediation, and post-incident.
- Architecture docs must map systems to folders and delivery pipelines.
- Keep docs aligned when templates or folder structures change.

## Quality Bar

- No stale links.
- No ambiguous placeholders in production guidance.
- No undocumented exceptions to security or operational standards.
- Every major template family should have usage guidance in docs/guides or docs/golden-paths.
