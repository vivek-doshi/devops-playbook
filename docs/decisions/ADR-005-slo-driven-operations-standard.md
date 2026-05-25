# ADR-005: SLO-Driven Operations as a Repository Standard

**Date:** 2026-05-25
**Status:** Accepted

---

## Context

The repository now includes end-to-end reliability artifacts:
- SLO schemas and definitions in `observability/prometheus/slos/`
- Recording rules and burn-rate alerts in `observability/prometheus/recording-rules/` and `observability/prometheus/alerts/`
- Operational response runbooks in `docs/runbooks/`
- Golden-path guidance in `docs/golden-paths/slo-driven-development.md`

Without an explicit decision, teams may treat SLOs as optional documentation instead of operational controls.

## Decision

Adopt SLO-driven operations as the default reliability model for production services represented in this repository.

Required elements:
1. Service-level SLO definition.
2. Multi-window burn-rate alerting.
3. Runbook linkage for each reliability alert.
4. Error-budget policy with decision thresholds.

## Rationale

- Reliability work becomes measurable and comparable across services.
- Burn-rate alerts reduce noise while preserving urgency for real degradations.
- Runbook-linked alerts improve response speed and consistency.

## Consequences

Positive:
- Standardized reliability governance.
- Clear trigger points for feature velocity vs reliability trade-offs.

Trade-offs:
- Initial setup overhead for teams onboarding legacy services.
- Alert tuning effort required to avoid false positives.

Mitigations:
- Provide baseline templates and runbooks.
- Review thresholds quarterly and tune based on historical data.

## Repository Mapping

- SLO definitions: `observability/prometheus/slos/`
- Recording rules: `observability/prometheus/recording-rules/`
- Alerts: `observability/prometheus/alerts/`
- Reliability runbooks: `docs/runbooks/`
- Guidance: `docs/golden-paths/slo-driven-development.md`
