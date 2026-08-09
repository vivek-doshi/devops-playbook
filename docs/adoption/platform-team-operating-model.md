---
Last reviewed: 2026-06-27
Owner: Platform team
---

# Platform Team Operating Model

Audience: Platform team lead and Engineering VP.

## Team Topology

This playbook aligns with Team Topologies by positioning the platform group as a dedicated Platform team and product/application groups as Stream-aligned teams.

Operating interaction modes:
- X-as-a-Service for mature golden paths where interfaces are stable and onboarding is repeatable.
- Collaboration during onboarding windows, major architecture migrations, and policy graduation phases.

Thickening vs thinning guidance:
- Thicken the platform when repeated onboarding friction appears across teams.
- Thin the platform when capabilities are stable and can be exposed as self-service templates and guardrails.

## Core Accountabilities

| Domain | Platform team owns | Application team owns | Shared |
|---|---|---|---|
| Cluster lifecycle | Cluster bootstrap, upgrades, baseline add-ons, cluster policy plumbing | Workload readiness for platform upgrades | Change windows and release communication |
| Golden paths | Authoring, maintenance, versioning, documentation | Adoption, feedback, service-specific adaptation | Gap analysis and backlog prioritization |
| Security policy | Policy authoring pipeline, graduation workflow, exception governance | Workload conformance and remediation | Risk acceptance and rollout timing |
| Secret infrastructure | ESO/secret store integration, rotation frameworks | Secret definitions and runtime usage | Rotation events and outage handling |
| Observability stack | Prometheus/Loki/Tempo operation and upgrade | Service metrics, tracing, and runbooks | Alert tuning and incident review |
| FinOps tooling | Cost dashboards, policy automation, optimization PR loop | Service-level cost ownership and execution | Budget review and rightsizing decisions |
| Catalog and CODEOWNERS | Catalog schema/tooling, CODEOWNERS generation | Service metadata quality and ownership updates | Ownership model governance |
| Incident response tooling | Alert routing backbone, pager integrations, response templates | First response for service incidents | SEV escalation and PIR action tracking |
| Disaster recovery | Platform-level backup/restore capabilities and drills | Service-level recovery validation | Cross-team DR readiness exercises |

## Platform Roadmap Cadence

Quarterly:
- Maturity model review in `docs/adoption/maturity-model.md`.
- ADR backlog review in `docs/decisions/`.
- Golden path gap analysis across onboarding outcomes.

Monthly:
- SLO review using `docs/runbooks/slo-quarterly-review.md` preparation data.
- FinOps optimization loop review.
- Policy violation report and exception expiry review.

Weekly:
- Platform standups and blocker triage.
- PR review SLA target: less than 2 business days for playbook PRs.

On-demand:
- Exception/waiver decisions through `docs/adoption/exception-waiver-process.md`.
- New team onboarding and migration planning.

## Inner Loop vs Outer Loop

Inner loop:
- Developer laptop -> pre-commit -> Kind cluster -> CI.
- Goal: fastest possible feedback with policy and quality checks left-shifted.

Outer loop:
- PR -> CI -> staging deploy -> production deploy -> SLO signal -> incident -> PIR -> ADR update.
- Goal: safe, observable change with institutional learning.

Platform team mission:
- Make both loops faster and safer.
- Avoid becoming manual gatekeepers for routine service operations.

## Platform SLAs To Application Teams

| Service type | SLA |
|---|---|
| New namespace provisioning | Less than 2 business days |
| Golden path PR review | Less than 2 business days |
| Incident escalation response (SEV-1) | Less than 15 minutes |
| New secret store onboarding | Less than 1 week |
| Exception triage response | Less than 2 business days |

## Toil Budget

Target:
- Platform team spends no more than 30% of engineering capacity on undifferentiated toil.

Toil examples:
- Repetitive manual cluster edits.
- Re-running known remediation commands without automation.
- Repeated one-off onboarding tasks that should be templatized.

Investment examples:
- Golden path improvements.
- Reusable policy, compliance, and FinOps automation.
- Documentation and self-service workflows that reduce future support load.

Monthly toil tracking template:

| Month | Team capacity (hours) | Toil hours | Toil % | Top toil driver | Automation action |
|---|---|---|---|---|---|
| YYYY-MM | | | | | |

## On-Call Model

Platform team on-call scope:
- Cluster control plane health.
- ESO and secret infrastructure.
- ArgoCD and GitOps control plane.
- Prometheus/Alertmanager stack.
- Kyverno admission webhook health.

Application team on-call scope:
- Their own services, data paths, and service-specific runbooks.

Escalation path:
- Application team -> Platform team -> Cloud vendor support.
