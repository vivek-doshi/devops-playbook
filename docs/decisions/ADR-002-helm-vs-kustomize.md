# ADR-002: Helm vs Kustomize

**Date:** 2026-02-28
**Status:** Accepted

---

## Context

For Kubernetes manifest management, two leading tools were considered: **Helm** and **Kustomize**.

## Decision

**Include both, with guidance on when to use each.**

| | Helm | Kustomize |
|-|------|-----------|
| **Use case** | Distributable, versioned releases | In-repo environment patches |
| **Learning curve** | Higher (Go templates + chart concepts) | Lower (YAML overlays) |
| **Reuse** | Best for shared charts (internal registry) | Best for single-repo overlays |
| **Secret management** | Via Helm Secrets plugin | Via Sealed Secrets / external-secrets |

## Rationale

- **Kustomize** (`cd/kubernetes/`) is the recommended starting point. It is kubectl-native, requires no extra tooling, and keeps YAML readable.
- **Helm** (`cd/helm/`) is recommended when: (1) packaging for multiple teams, (2) using the public chart ecosystem, or (3) complex conditional logic is needed.

## Consequences

- Teams must choose one approach per application and be consistent — mixing Helm and raw Kustomize for the same app increases complexity.
- This repository provides both to serve different team maturity levels.
