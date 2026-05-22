# Terminology

Defines canonical language for this repository. Use these terms consistently in docs, templates, and reviews.

## Canonical Terms

- Golden path: Preferred implementation workflow; not optional guidance.
- Template: Reusable starting file intended for adaptation by teams.
- Guardrail: Mandatory safety or governance control embedded into templates and processes.
- Baseline: Minimum acceptable standard for production readiness.
- Pattern: Reusable technical approach, often represented as a template family.
- Runbook: Action-oriented operational procedure for incidents or routine operations.
- Target: Deployment destination template under cd/targets/.
- Overlay: Environment-specific customization on top of base Kubernetes manifests.
- Policy: Enforceable rule expressed in admission controls or CI checks.

## Word Choices

Use:

- production-grade defaults
- security by default
- explicit resource limits
- reusable templates
- multi-cloud parity
- policy enforcement

Avoid:

- best effort security
- optional limits
- one-off script unless clearly scoped and temporary
- ad hoc deployment path for standard workloads

## Review Language

In pull request reviews, prefer objective wording:

- aligns with golden path
- violates baseline guardrail
- missing required resource constraints
- introduces cloud-specific coupling without abstraction boundary
- lacks incident or rollback guidance
