# ADR-003: GitOps Strategy

**Date:** 2026-02-28
**Status:** Accepted

---

## Context

GitOps treats the Git repository as the single source of truth for cluster state. Two tools dominate the space: **ArgoCD** and **Flux**.

## Decision

**Include templates for both ArgoCD and Flux. Recommend ArgoCD as the default.**

## Rationale

**ArgoCD** is recommended because:
- Rich web UI aids adoption and debugging
- Application CRD is intuitive
- Active community and wide adoption
- App-of-Apps and ApplicationSet patterns scale well

**Flux** is included because:
- Preferred by teams with Helm-heavy stacks (Flux HelmRelease CRD)
- Better multi-tenancy model for large organisations
- Pure pull-based (no in-cluster API server exposure)

## GitOps Principles Applied

1. **Declarative**: All desired state defined in YAML
2. **Versioned**: Git history is the audit log
3. **Pulled**: Cluster pulls from Git (not pushed to)
4. **Continuously reconciled**: Drift is automatically corrected

## Consequences

- Config repo (GitOps repo) should be separate from app code repo to keep concerns clean.
- Secrets must never be committed in plaintext — use Sealed Secrets, External Secrets Operator, or Vault Agent Injector.
