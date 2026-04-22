<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# ADR-001: Repository Folder Structure

**Date:** 2026-02-28
<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Status:** Accepted

---

<!-- Note 3: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Context

We needed a reference repository structure for CI/CD templates that would be:
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Easy to navigate for engineers from different tech backgrounds
- Organised by concern (What? → Where to look)
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Scalable as we add new platforms and technologies

Multiple approaches were considered:
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
1. Flat structure (all pipelines in one folder)
2. Organised by platform (github/, gitlab/, azure/)
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
3. Organised by stage (ci/, cd/, security/)

## Decision

<!-- Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Organise by functional concern first, then by platform and technology.**

Top-level folders correspond to stages of the engineering lifecycle:
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- `docker/` → Containerization
- `compose/` → Local development
<!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- `ci/` → Build & test
- `cd/` → Deployment
<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- `security/` → Scanning
- `quality/` → Standards

Within each folder, sub-folders reflect platform or tech stack.

## Rationale

- Engineers typically ask "I need to deploy to AKS" rather than "I need a GitHub Actions file"
- The concern-first organisation mirrors how teams think about problems
- Allows progressive disclosure: start at the top level, drill down as needed

## Consequences

- Some files could logically live in multiple places (e.g., a security scan could be in `ci/` or `security/`). Convention: generic/reusable templates in `security/`, integrated pipeline steps in `ci/`.
- Platform folders within `ci/` may grow large over time — addressed with `_shared/` and `_strategies/` sub-folders.
