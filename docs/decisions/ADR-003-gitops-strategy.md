<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# ADR-003: GitOps Strategy

**Date:** 2026-02-28
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Status:** Accepted

---

<!-- Note 3: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Context

GitOps treats the Git repository as the single source of truth for cluster state. Two tools dominate the space: **ArgoCD** and **Flux**.

<!-- Note 4: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Decision

**Include templates for both ArgoCD and Flux. Recommend ArgoCD as the default.**

<!-- Note 5: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Rationale

**ArgoCD** is recommended because:
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Rich web UI aids adoption and debugging
- Application CRD is intuitive
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Active community and wide adoption
- App-of-Apps and ApplicationSet patterns scale well

<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Flux** is included because:
- Preferred by teams with Helm-heavy stacks (Flux HelmRelease CRD)
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Better multi-tenancy model for large organisations
- Pure pull-based (no in-cluster API server exposure)

<!-- Note 10: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## GitOps Principles Applied

1. **Declarative**: All desired state defined in YAML
2. **Versioned**: Git history is the audit log
3. **Pulled**: Cluster pulls from Git (not pushed to)
4. **Continuously reconciled**: Drift is automatically corrected

## Consequences

- Config repo (GitOps repo) should be separate from app code repo to keep concerns clean.
- Secrets must never be committed in plaintext — use Sealed Secrets, External Secrets Operator, or Vault Agent Injector.
