# ADR-002: Helm and Kustomize Usage Strategy

**Date:** 2026-05-25
**Status:** Accepted

---

## Context

The repository supports Kubernetes delivery patterns for teams with different maturity levels.

Current structure includes:
- Kustomize-first assets in `cd/kubernetes/` with `_base/`, `_overlays/`, and `_patterns/`.
- Helm assets in `cd/helm/` for chart-oriented packaging and reuse.

A single mandatory tool would simplify guidance but would block valid use cases:
- Teams consuming ecosystem charts expect Helm workflows.
- Teams managing in-repo overlays with low templating complexity prefer Kustomize.

## Decision

Support both tools with explicit default and selection criteria:
1. Default to Kustomize for in-repo application deployment in this repository.
2. Use Helm for distributable package scenarios or when chart ecosystem reuse is required.
3. Do not mix Helm and Kustomize as parallel source-of-truth for the same application release path.

## Selection Criteria

Use Kustomize when:
- The service is managed directly in this repository.
- Environment differences are overlay-driven.
- Readability and low cognitive overhead are priorities.

Use Helm when:
- You need versioned, reusable packaging across teams.
- You depend on upstream/public chart ecosystems.
- You need robust chart value contracts and release packaging semantics.

## Rationale

- `cd/kubernetes/` already models base-plus-overlay patterns that map well to GitOps promotion.
- `cd/helm/` provides practical chart templates for reusable deployment artifacts.
- Supporting both reflects real-world platform heterogeneity while preserving clear defaults.

## Consequences

Positive:
- Teams can adopt an approach that matches operational needs.
- Repository remains practical for both platform and product teams.

Trade-offs:
- Increased guidance surface area and potential inconsistency.

Mitigations:
- Enforce one primary manifest source per app.
- Capture app-level choice in service docs and deployment guides.
- Use CI policy checks to prevent parallel conflicting definitions.

## Repository Mapping

- Kustomize path: `cd/kubernetes/`
- Helm path: `cd/helm/`
- Related strategy docs: `docs/guides/environment-strategy.md`, `docs/decisions/ADR-003-gitops-strategy.md`
