# ADR-004: Policy Enforcement Layering (CI + Admission)

**Date:** 2026-05-25
**Status:** Accepted

---

## Context

The repository contains policy artifacts in both pre-deploy and deploy-time layers:
- Static policy evaluation in `policy/conftest/` and `ci-security/iac-scanning/`
- Admission controls in `policy/kyverno/`
- Security and compliance mappings in `secops/compliance/`

A single-layer policy model creates blind spots:
- CI-only cannot stop direct cluster drift.
- Admission-only gives slower developer feedback and higher remediation cost.

## Decision

Adopt a layered policy model:
1. Shift-left checks in CI for fast feedback and pull request gating.
2. Admission enforcement in Kubernetes for runtime protection.
3. Control mapping and evidence generation for compliance reporting.

## Rationale

- Catching issues early reduces remediation cost and review churn.
- Admission policies block unsafe changes regardless of CI bypass scenarios.
- Compliance traceability requires both enforcement and evidence collection.

## Consequences

Positive:
- Defense-in-depth for policy and security controls.
- Better audit posture and operational consistency.

Trade-offs:
- More policy maintenance and coordination effort.
- Potential duplicate signal if rule ownership is unclear.

Mitigations:
- Define policy ownership by domain.
- Keep CI checks and admission policies aligned but not redundant.
- Use docs to describe policy intent and expected failure modes.

## Repository Mapping

- Static checks: `policy/conftest/`, `ci-security/`
- Admission checks: `policy/kyverno/`
- Compliance evidence: `secops/compliance/`
