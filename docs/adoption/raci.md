---
Last reviewed: 2026-06-27
Owner: Platform team
---

# RACI Matrix - DevOps / SecOps / FinOps / Application Teams / Leadership

## How to use this RACI

RACI is a decision-clarity tool. `R` means the role that executes the work. `A` means the single role that owns final decision and outcome. `C` means roles that must be consulted before finalizing. `I` means stakeholders who should be informed of progress and results.

Each activity must have exactly one `A`. Multiple `R` entries are acceptable when execution is distributed, but decision ownership cannot be shared. If an activity appears repeatedly delayed, verify the `A` assignment first.

Worked example: Kyverno policy graduation from Audit to Enforce has `SecOps / GRC` as `A`, `Platform Eng` as `R`, with `App Team`, `FinOps`, and `Eng Lead / Architect` as `C` where scope warrants. This keeps security accountability clear while preserving platform execution velocity.

Columns:
- `Platform Eng`
- `App Team`
- `SecOps / GRC`
- `FinOps`
- `DBA`
- `Eng Lead / Architect`
- `CISO / VP Eng`

## CI/CD & Delivery

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Golden path selection for a new service | R | C | C | I | I | A | I |
| CI workflow implementation and maintenance | R | R | C | I | I | A | I |
| Reusable workflow updates (`ci/github-actions/_shared/`) | R | C | C | I | I | A | I |
| Image registry management | A | I | C | I | I | C | I |
| ArgoCD ApplicationSet management | A | C | C | I | I | C | I |
| GitOps promotion approval (dev -> staging -> prod) | R | C | C | I | I | A | I |

## Infrastructure & IaC

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Terraform module authoring (`terraform/`) | R | C | C | C | C | A | I |
| Terraform apply for production clusters | R | I | C | C | I | A | I |
| Remote state backend management | A | I | C | I | I | C | I |
| Cost delta review for Terraform PRs (Infracost) | C | I | I | A | I | C | I |
| Database provisioning and backup configuration | C | C | C | I | A | C | I |

## Security & Supply Chain

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Kyverno policy authoring | R | C | A | I | I | C | I |
| Kyverno policy graduation (Audit -> Enforce) | R | C | A | C | I | C | I |
| Exception/waiver approval (see `docs/adoption/exception-waiver-process.md`) | R | C | A | I | I | C | C |
| OIDC trust policy updates for keyless signing | R | I | A | I | I | C | I |
| Supply chain policy exceptions | R | C | A | I | I | C | C |
| Security vulnerability triage (container CVEs) | R | C | A | I | I | C | I |
| Incident response IC role | C | R | A | I | I | C | I |
| Post-incident review facilitation | R | C | C | I | I | A | I |

## Secrets & Identity

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| OIDC federation configuration | R | I | A | I | I | C | I |
| ESO ClusterSecretStore management | A | C | C | I | I | I | I |
| Secret rotation policy definition | C | C | A | I | C | C | I |
| Emergency secret rotation execution | R | C | A | I | C | I | I |
| Secret offboarding during service decommission | R | R | A | I | C | C | I |

## Observability & SLOs

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Prometheus/Loki/Tempo stack upgrades | A | I | C | I | I | C | I |
| SLO definition per service | C | R | I | I | I | A | I |
| Alert rule authoring | C | R | C | I | I | A | I |
| Alert routing configuration (PagerDuty/Slack) | A | C | C | I | I | C | I |
| SLO quarterly review facilitation | R | C | I | C | I | A | I |
| Error budget policy approval | C | C | C | I | I | A | I |

## FinOps

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Cost label schema updates (`finops/docs/cost-tagging-schema.md`) | C | C | I | A | I | C | I |
| Budget definition and approval (`finops/config/budgets.yaml`) | I | C | I | R | I | C | A |
| Rightsizing PR generation | C | R | I | A | I | C | I |
| Rightsizing PR approval and merge | C | A | I | R | I | C | I |
| Reserved capacity commitment approval | I | I | I | R | I | C | A |
| Monthly chargeback report distribution | I | I | I | A | I | C | I |

## Governance & Compliance

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| Control library maintenance (`secops/compliance/control-library/`) | C | I | A | I | I | C | I |
| Evidence collection scheduling (`secops/compliance/kubernetes/compliance-report-cronjob.yaml`) | R | I | A | I | I | C | I |
| Compliance report review before audit | C | I | A | I | I | C | I |
| Auditor communication | I | I | R | I | I | C | A |
| ADR authoring | R | C | C | C | C | A | I |
| ADR ratification | C | I | C | I | I | R | A |
| Exception/waiver final approval | C | I | R | I | I | C | A |

## Platform Onboarding

| Activity | Platform Eng | App Team | SecOps / GRC | FinOps | DBA | Eng Lead / Architect | CISO / VP Eng |
|---|---|---|---|---|---|---|---|
| New team onboarding facilitation (`docs/golden-paths/platform-onboarding.md`) | A | C | C | I | I | C | I |
| Namespace provisioning | A | I | C | I | I | C | I |
| Service catalog registration (new service) | C | R | I | I | I | A | I |
| Runbook authoring (per service) | C | R | I | I | I | A | I |
| CODEOWNERS generation | R | C | I | I | I | A | I |

Gap check:
- No activities are missing an `R`.
- Every activity has exactly one `A`.
