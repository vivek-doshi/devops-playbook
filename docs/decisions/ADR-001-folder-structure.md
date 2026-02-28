# ADR-001: Repository Folder Structure

**Date:** 2026-02-28
**Status:** Accepted

---

## Context

We needed a reference repository structure for CI/CD templates that would be:
- Easy to navigate for engineers from different tech backgrounds
- Organised by concern (What? → Where to look)
- Scalable as we add new platforms and technologies

Multiple approaches were considered:
1. Flat structure (all pipelines in one folder)
2. Organised by platform (github/, gitlab/, azure/)
3. Organised by stage (ci/, cd/, security/)

## Decision

**Organise by functional concern first, then by platform and technology.**

Top-level folders correspond to stages of the engineering lifecycle:
- `docker/` → Containerization
- `compose/` → Local development
- `ci/` → Build & test
- `cd/` → Deployment
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
