# ADR-003: GitOps Strategy and Controller Default

**Date:** 2026-05-25
**Status:** Accepted

---

## Context

This repository defines GitOps patterns for single-cluster and multi-cluster delivery.

Implemented assets include:
- Argo CD patterns in `cd/gitops/argocd/`
- Flux patterns in `cd/gitops/flux/`
- Fleet-oriented Argo CD overlays and registry-driven ApplicationSet assets in `cd/fleet-overlays/` and `cd/gitops/argocd/fleet/`

The team needed a default controller recommendation while preserving interoperability for organizations that already standardize on Flux.

## Decision

Adopt Argo CD as the default GitOps controller in this repository while maintaining Flux examples as supported alternatives.

Operational model:
1. Git is the source of truth for desired state.
2. Controllers pull and reconcile continuously.
3. Promotion occurs through Git pull requests across environment overlays.
4. Manual direct cluster mutations are treated as exceptions.

## Rationale

Argo CD default rationale:
- Strong visibility and troubleshooting UX for broad adoption.
- Mature ApplicationSet and app-of-apps patterns for scale.
- Repository already contains richer Argo CD examples and fleet artifacts.

Flux inclusion rationale:
- Existing user base and strong Helm-native workflows.
- Useful for teams preferring a pull-only operator model and different tenancy patterns.

## Consequences

Positive:
- Clear default reduces decision latency for new adopters.
- Flux compatibility preserves portability.
- GitOps behavior remains aligned with auditability and drift correction goals.

Trade-offs:
- Documentation and testing burden increases with two supported controllers.
- Teams can fragment if selection is not documented per service.

Mitigations:
- Require each service/deployment path to document controller choice.
- Keep base deployment manifests portable and controller-agnostic where possible.

## Fleet Scale Notes

For the Argo CD fleet model in this repo:
- Cluster registry is intentionally human-maintained for explicit control.
- Recommended practical scale limit is 20 clusters per fleet ApplicationSet before introducing higher-order partitioning.
- `ApplyOutOfSyncOnly` and backoff controls remain required for large fleet stability.

## Repository Mapping

- Argo CD: `cd/gitops/argocd/`
- Flux: `cd/gitops/flux/`
- Fleet overlays: `cd/fleet-overlays/`
- Fleet registry assets: `cd/gitops/argocd/fleet/`
