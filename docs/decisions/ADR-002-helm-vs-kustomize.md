<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# ADR-002: Helm vs Kustomize

**Date:** 2026-02-28
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Status:** Accepted

---

<!-- Note 3: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Context

For Kubernetes manifest management, two leading tools were considered: **Helm** and **Kustomize**.

<!-- Note 4: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Decision

**Include both, with guidance on when to use each.**

<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| | Helm | Kustomize |
|-|------|-----------|
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Use case** | Distributable, versioned releases | In-repo environment patches |
| **Learning curve** | Higher (Go templates + chart concepts) | Lower (YAML overlays) |
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| **Reuse** | Best for shared charts (internal registry) | Best for single-repo overlays |
| **Secret management** | Via Helm Secrets plugin | Via Sealed Secrets / external-secrets |

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Rationale

- **Kustomize** (`cd/kubernetes/`) is the recommended starting point. It is kubectl-native, requires no extra tooling, and keeps YAML readable.
- **Helm** (`cd/helm/`) is recommended when: (1) packaging for multiple teams, (2) using the public chart ecosystem, or (3) complex conditional logic is needed.

## Consequences

- Teams must choose one approach per application and be consistent — mixing Helm and raw Kustomize for the same app increases complexity.
- This repository provides both to serve different team maturity levels.
