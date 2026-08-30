# Architecture Decision Records (ADRs)

This folder captures major technical and operational decisions for this repository.

For organization-scale rollout guidance, see `docs/adoption/`. Adoption decisions that are specific to your organization should be captured as ADRs in this folder and linked from `docs/adoption/30-60-90-plan.md`.

## Current ADRs

- `ADR-001-folder-structure.md`: Concern-first repository structure and navigation model.
- `ADR-002-helm-vs-kustomize.md`: Kubernetes packaging strategy and tool-selection criteria.
- `ADR-003-gitops-strategy.md`: GitOps controller default and operating model.
- `ADR-004-policy-enforcement-layering.md`: Layered policy enforcement across CI and admission.
- `ADR-005-slo-driven-operations-standard.md`: SLO-driven operations as the reliability baseline.

## ADR Lifecycle

Status values:
- Proposed
- Accepted
- Superseded
- Deprecated

When adding a new ADR:
1. Use the next sequence number.
2. Describe context, decision, rationale, and consequences.
3. Cross-reference affected folders and guides.
4. Update this index file.
