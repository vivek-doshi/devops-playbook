---
Last reviewed: 2026-06-27
Owner: Platform team
---

# Platform Maturity Model - Crawl / Walk / Run

This model helps platform and engineering leaders assess current capability and sequence adoption investments. Use it with `docs/adoption/30-60-90-plan.md` for execution.

## Domain Maturity Matrix

### CI/CD

#### Crawl (weeks 1-4)

What done looks like:
- Team-wide local bootstrap and pre-commit hooks are active.
- At least one CI template runs on every pull request.
- Branch protections require review and status checks.

Playbook assets:
- `scripts/env-checker.sh`
- `.pre-commit-config.yaml`
- `ci/github-actions/`
- `docs/golden-paths/platform-onboarding.md`

Timeline hint:
- Complete in the first 2-4 weeks for pilot services.

#### Walk (weeks 5-12)

What done looks like:
- Reusable workflows are standardized across repos.
- GitOps promotions are documented and repeatable.
- Release/version strategy is enforced via CI.

Playbook assets:
- `ci/github-actions/_shared/`
- `cd/gitops/`
- `docs/guides/branching-strategy.md`
- `docs/guides/versioning-strategy.md`

Timeline hint:
- Complete by end of month 3.

#### Run (month 4+)

What done looks like:
- Golden paths are self-service and observable.
- CI policy and quality gates are enforced by default.
- Teams onboard with minimal platform pairing.

Playbook assets:
- `docs/golden-paths/`
- `ci/README.md`
- `cd/README.md`
- `.github/workflows/repo-quality.yml` (required rollout gate)

Timeline hint:
- Start in month 4 and continuously improve.

### Security & Supply Chain

#### Crawl (weeks 1-4)

What done looks like:
- Baseline admission policies run in Audit mode.
- OIDC federation is established for primary cloud accounts.
- Secret scanning and basic SAST run in CI.

Playbook assets:
- `policy/kyverno/`
- `docs/guides/github-actions-oidc.md`
- `ci-security/secret-detection/`
- `ci-security/sast/`

Timeline hint:
- Complete before first production onboarding.

#### Walk (weeks 5-12)

What done looks like:
- Signed images, SBOM checks, and provenance checks run on pilot services.
- ESO-backed secrets replace static credentials on pilots.
- Policy graduation process (Audit to Enforce) is active in non-prod.

Playbook assets:
- `secops/supply-chain/cosign-verify-policy.yaml`
- `secops/supply-chain/sbom-policy.yaml`
- `secops/supply-chain/slsa-verify.yaml`
- `secrets/external-secrets/`
- `docs/adoption/exception-waiver-process.md`

Timeline hint:
- Complete by day 60 for pilot scope.

#### Run (month 4+)

What done looks like:
- Enforce mode is active for stable policies in production.
- Exception workflow is auditable, time-boxed, and reviewed.
- Compliance evidence for control implementation is continuously collected.

Playbook assets:
- `policy/kyverno/`
- `docs/adoption/exception-waiver-process.md`
- `docs/adoption/control-evidence-map.md`
- `secops/compliance/scripts/collect-evidence.sh`

Timeline hint:
- Begin month 4; maintain quarterly review.

### Observability & SLOs

#### Crawl (weeks 1-4)

What done looks like:
- Core telemetry stack deployed in at least one environment.
- Alert routing is configured for pilot services.
- Each pilot service has one baseline SLO.

Playbook assets:
- `observability/prometheus/`
- `notifications/`
- `docs/golden-paths/slo-driven-development.md`

Timeline hint:
- Establish in first 30 days.

#### Walk (weeks 5-12)

What done looks like:
- Multi-window burn-rate recording and alerts are enabled.
- Runbooks exist for top reliability alerts.
- Quarterly SLO review cadence is scheduled.

Playbook assets:
- `observability/prometheus/recording-rules/`
- `observability/prometheus/alerts/`
- `docs/runbooks/slo-quarterly-review.md`
- `docs/runbooks/`

Timeline hint:
- Fully operational by day 60.

#### Run (month 4+)

What done looks like:
- SLO and error budget policies guide delivery decisions.
- Incident-to-ADR feedback loop is institutionalized.
- Reliability posture is reviewed with leadership each quarter.

Playbook assets:
- `docs/golden-paths/incident-response.md`
- `docs/decisions/ADR-005-slo-driven-operations-standard.md`
- `docs/decisions/`

Timeline hint:
- Month 4 onward.

### FinOps

#### Crawl (weeks 1-4)

What done looks like:
- Cost tagging schema is adopted for pilot services.
- Initial budgets are defined for platform and pilot teams.
- Teams can view baseline spend trends.

Playbook assets:
- `finops/docs/cost-tagging-schema.md`
- `finops/config/budgets.yaml`
- `finops/README.md`

Timeline hint:
- Complete initial setup in first month.

#### Walk (weeks 5-12)

What done looks like:
- Cost-label policies run in Audit mode.
- Kubecost/OpenCost visibility is available.
- Rightsizing opportunities are identified in review cycles.

Playbook assets:
- `policy/kyverno/enforce-finops-labels.yaml`
- `finops/dashboards/`
- `finops/scripts/`
- `docs/golden-paths/finops-optimization.md`

Timeline hint:
- Operational by day 60.

#### Run (month 4+)

What done looks like:
- FinOps label enforcement is active in production.
- Rightsizing PR loop is running and tracked.
- Reserved capacity decisions include risk scoring.

Playbook assets:
- `finops/scripts/generate-optimization-pr.py`
- `finops/config/budgets.yaml`
- `docs/golden-paths/finops-optimization.md`

Timeline hint:
- Month 4+ steady state.

### Platform Governance

#### Crawl (weeks 1-4)

What done looks like:
- Platform team charter and ownership boundaries are documented.
- Initial service catalog entries exist for top production services.
- ADR process and templates are understood by leads.

Playbook assets:
- `docs/adoption/platform-team-operating-model.md`
- `catalog/services/`
- `docs/decisions/README.md`

Timeline hint:
- Complete within first 30 days.

#### Walk (weeks 5-12)

What done looks like:
- RACI is published and used during planning and incidents.
- Exception and waiver process is active.
- Compliance reporting cadence is established.

Playbook assets:
- `docs/adoption/raci.md`
- `docs/adoption/exception-waiver-process.md`
- `docs/golden-paths/compliance-reporting.md`

Timeline hint:
- Day 31-60 target.

#### Run (month 4+)

What done looks like:
- Governance decisions are auditable and routinely reviewed.
- Compliance evidence maps to controls with minimal manual effort.
- Onboarding and policy exceptions scale without platform bottlenecks.

Playbook assets:
- `docs/adoption/control-evidence-map.md`
- `secops/compliance/control-library/`
- `docs/adoption/README.md`

Timeline hint:
- Month 4 onward with quarterly updates.

## Where Is Your Team Today?

Score each question as checked (`[x]`) for yes and unchecked (`[ ]`) for no.

### CI/CD Self-Assessment

- [ ] CI runs on every PR for all production services.
- [ ] Pre-commit hooks are installed and required for platform repos.
- [ ] Branch protections are enabled on default branches.
- [ ] Reusable workflows are adopted across service repos.
- [ ] GitOps promotion path is documented and consistently used.

### Security & Supply Chain Self-Assessment

- [ ] OIDC federation is configured for primary cloud accounts.
- [ ] Kyverno policies run in cluster with measurable results.
- [ ] Pilot images are signed and verified.
- [ ] SBOM and provenance checks run in CI/CD.
- [ ] Exception process is documented and auditable.

### Observability & SLOs Self-Assessment

- [ ] Prometheus/Alertmanager stack is running in non-prod and prod.
- [ ] Each production service has at least one SLO definition.
- [ ] Burn-rate alerting is enabled.
- [ ] Alert runbooks exist for top scenarios.
- [ ] Quarterly SLO review is on calendar.

### FinOps Self-Assessment

- [ ] Cost tag schema is applied to production workloads.
- [ ] Budget file is defined and reviewed monthly.
- [ ] Cost label policy is enforced or in graduation plan.
- [ ] Rightsizing recommendations are generated and tracked.
- [ ] Chargeback/showback reporting is shared with leadership.

### Platform Governance Self-Assessment

- [ ] Platform operating model is documented and agreed.
- [ ] RACI is published and used for dispute resolution.
- [ ] Top production services are in `catalog/services/`.
- [ ] Exception/waiver records are tracked in Git.
- [ ] ADR lifecycle is active for architecture decisions.

Placement guidance:
- 0-2 yes per domain: Crawl.
- 3-4 yes per domain: Walk.
- 5 yes per domain: Run.

## Maturity Cross-Reference

| Level | Golden path | ADR anchor |
|---|---|---|
| Crawl | `docs/golden-paths/platform-onboarding.md` | `docs/decisions/ADR-001-folder-structure.md` |
| Walk | `docs/golden-paths/compliance-reporting.md` | `docs/decisions/ADR-004-policy-enforcement-layering.md` |
| Run | `docs/golden-paths/slo-driven-development.md` | `docs/decisions/ADR-005-slo-driven-operations-standard.md` |
