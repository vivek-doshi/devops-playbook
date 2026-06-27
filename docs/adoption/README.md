---
Last reviewed: 2026-06-27
Owner: Platform team
---

# Enterprise Adoption Kit

## What this kit is

This repository already provides golden paths for building, deploying, and operating services. The Enterprise Adoption Kit provides the organizational layer required to roll those practices out across many teams.

Use this kit when scaling from pilot to organization-wide operating model. It translates platform assets into governance, ownership, rollout sequencing, exceptions, and audit evidence.

## Who reads what

| Role | Start here |
|---|---|
| Platform team lead | `maturity-model.md` -> `30-60-90-plan.md` -> `platform-team-operating-model.md` |
| Engineering VP / CTO | `maturity-model.md` -> `raci.md` -> `30-60-90-plan.md` (executive sections) |
| Application team lead | `raci.md` -> `exception-waiver-process.md` |
| CISO / Security lead | `control-evidence-map.md` -> `exception-waiver-process.md` |
| GRC / Audit | `control-evidence-map.md` -> `docs/golden-paths/compliance-reporting.md` |

## Rollout status tracker

- [ ] Platform operating model agreed and published.
- [ ] Top 10 production services registered in `catalog/services/`.
- [ ] Environment checker run by all platform engineers (`scripts/env-checker.sh`).
- [ ] Kind cluster verified on all platform engineer machines.
- [ ] Pre-commit hooks installed and enforced.
- [ ] OIDC configured for top 3 cloud accounts.
- [ ] Remote Terraform state bootstrapped for production account.
- [ ] One end-to-end golden path validated.
- [ ] Kyverno installed in Audit mode on non-prod.
- [ ] Prometheus deployed and at least one SLO per pilot service defined.
- [ ] Quality gate workflow path reviewed (`.github/workflows/repo-quality.yml`).
- [ ] Non-prod policy graduation complete for `require-non-root` and `require-resource-limits`.
- [ ] ESO deployed and pilot secrets migrated.
- [ ] Supply chain signing and SBOM checks enabled for pilot services.
- [ ] Compliance evidence pipeline operational with first report generated.
- [ ] Second app team onboarded through platform onboarding path.
- [ ] Alert runbooks completed for top pilot scenarios.
- [ ] SLO quarterly review scheduled.
- [ ] Production Enforce mode active for stable Kyverno and supply-chain controls.
- [ ] All production services cataloged with validated SLO definitions.
- [ ] FinOps label enforcement in Enforce mode and first rightsizing PR merged.
- [ ] Exception process ratified and one exception processed end to end.
- [ ] Platform NPS survey completed with target >= 4.0/5.0 golden-path usefulness.
- [ ] DR drill completed using Velero restore in staging.
- [ ] Top 3 org-specific ADRs captured in `docs/decisions/`.

## Keeping this kit current

- Review cadence: quarterly, aligned with SLO quarterly review.
- Owner: Platform team lead.
- Change process: PR to `docs/adoption/`, reviewed by Eng Lead and GRC.

## Documents in this kit

- `maturity-model.md`
- `30-60-90-plan.md`
- `platform-team-operating-model.md`
- `raci.md`
- `exception-waiver-process.md`
- `control-evidence-map.md`
