# Retrieval Priority

Priority order for selecting files during assistant retrieval.

## Priority Levels

- P0 (Mandatory first read)
  - README.md
  - docs/ARCHITECTURE_DECISION_GUIDE.md
  - relevant docs/golden-paths/*.md
- P1 (Domain grounding)
  - domain README files (ci/, cd/, terraform/, security/, finops/, observability/)
- P2 (Implementation templates)
  - stack-specific templates and cloud target files
- P3 (Operational and guardrail reinforcement)
  - policy/, secops/runbooks/, notifications/, quality/
- P4 (Optimization and advanced variants)
  - finops/scripts/, advanced patterns, optional integrations

## Routing Priority Overrides

- Incident/security request -> secops/runbooks and security/ move to P0.
- Cost/optimization request -> finops/ moves to P0.
- User names exact file -> requested file becomes P0.

## Stop Conditions

Stop retrieving when:

- intent is fully disambiguated
- target platform and workload type are known
- one valid implementation path is identified
- guardrails for security and resource limits are captured
