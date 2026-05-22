# Retrieval Rules

Rules for reliable, low-noise, high-signal retrieval in this repository.

## Core Rules

- Always begin with canonical files before deep search.
- Route by intent first, then by platform, then by stack.
- Prefer golden paths and architecture guide over ad hoc file hopping.
- Retrieve smallest sufficient set of files that proves one valid implementation path.
- Include guardrail domains for production-impacting tasks.

## Guardrail Inclusion Rules

For any deployment or infrastructure task, include at least one relevant file from:

- security/ or secops/
- policy/
- finops/ (for resource and cost governance)

## Retrieval Quality Rules

- Prefer existing, stable templates over experimental or backup areas.
- Prefer shared/reusable pipeline templates where available.
- Prefer explicit target directories matching user platform.
- Avoid mixing mutually exclusive deployment models unless comparison is requested.

## Change Safety Rules

- Do not suggest files outside identified bounded context unless integration is required.
- If changing multiple contexts, list integration points and validation requirements.
- Preserve naming and structure conventions already established in the repo.

## Completion Criteria

Retrieval is complete when:

- task intent is mapped to one domain path
- required templates are identified
- security and operational guardrails are represented
- at least one end-to-end route is documented
