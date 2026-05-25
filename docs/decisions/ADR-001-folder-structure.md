# ADR-001: Repository Folder Structure and Navigation Model

**Date:** 2026-05-25
**Status:** Accepted

---

## Context

This repository is not a single application. It is a reference platform for delivery, security, reliability, and operations patterns across multiple clouds and toolchains.

The structure must support:
- Fast discovery for engineers entering from different roles (developer, platform, SRE, security, FinOps).
- Reuse of templates without forcing one CI/CD provider or one cloud.
- Clear separation between implementation assets and operational guidance.
- Safe growth as new capabilities are added (for example SLO operations, service catalog, and FinOps loops).

Earlier options considered:
1. Flat layout: low upfront overhead but poor long-term navigability.
2. Platform-first layout: groups by provider but mixes lifecycle concerns.
3. Lifecycle/concern-first layout: groups by workflow intent, then by platform and technology.

## Decision

Use a concern-first top-level layout, then organize subfolders by platform, runtime, or strategy.

Top-level domains represent operational intent:
- Build and local runtime: `docker/`, `compose/`, `local-dev/`
- Delivery: `ci/`, `cd/`, `terraform/`, `backup/`
- Guardrails and security: `ci-security/`, `policy/`, `secops/`, `secrets/`
- Runtime operations: `observability/`, `notifications/`, `docs/runbooks/`
- Governance and optimization: `catalog/`, `finops/`
- Guidance and architecture records: `docs/`

Rules for placing new content:
1. Place executable templates in the domain folder, not in docs.
2. Place process guidance in `docs/guides/` or `docs/golden-paths/`.
3. Place operational response procedures in `docs/runbooks/`.
4. Capture structural and strategic choices in `docs/decisions/`.

## Rationale

- Engineers usually start from intent: "I need CI", "I need GitOps", "I need incident response".
- Concern-first layout reduces search time and onboarding friction.
- This model aligns with established repository domains already in active use.
- It supports progressive depth: high-level folder -> platform folder -> concrete template.

## Consequences

Positive:
- Better discoverability and onboarding.
- Easier mapping between docs and implementation folders.
- Scales to multi-cloud and multi-tool workflows without major reorganization.

Trade-offs:
- Some patterns can fit multiple domains (for example security checks in CI and runtime).
- Requires discipline to avoid duplicate content.

Mitigations:
- Keep a single canonical implementation location.
- Cross-reference from docs instead of duplicating templates.
- Record exceptions in ADRs and golden paths.
