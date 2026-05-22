# Bounded Contexts

Repository contexts and their boundaries for retrieval and change planning.

## Core Contexts

- Build Context
  - Scope: docker/, compose/, local-dev/
  - Concern: packaging and local runtime
- CI Context
  - Scope: ci/
  - Concern: build/test/scan automation
- CD Context
  - Scope: cd/
  - Concern: deployment orchestration and targets
- Infrastructure Context
  - Scope: terraform/, cd/pulumi/, backup/terraform/
  - Concern: infrastructure provisioning and lifecycle
- Security Context
  - Scope: security/, policy/, secrets/, secops/
  - Concern: prevention, detection, response, compliance
- Observability Context
  - Scope: observability/, notifications/
  - Concern: telemetry, alerting, diagnostics
- FinOps Context
  - Scope: finops/
  - Concern: spend visibility, cost governance, optimization
- Documentation Context
  - Scope: docs/, runbooks, guides
  - Concern: decision support and operational knowledge

## Boundary Rules

- Changes should remain in one primary context unless integration is required.
- Cross-context tasks must include integration files and validation steps.
- Guardrail contexts (security, policy, finops) are mandatory companions for production-impacting changes.
