# Copilot Instructions For This Repository

## Primary AI Context

Use `.ai/` as the canonical context root for all agent behavior in this repository.

Read in this order before making recommendations or edits:

1. `.ai/instructions/engineering-principles.md`
2. `.ai/instructions/coding-standards.md`
3. Domain-specific rules in `.ai/instructions/`
4. Repository context in `.ai/context/` — especially `project_details.md`, `repo-summary.md`, `architecture-overview.md`
5. Retrieval routing in `.ai/retrieval/` — use `task-routing.md` to identify the correct domain first

If guidance conflicts, follow this precedence:

1. `engineering-principles.md`
2. `security-rules.md`
3. Domain rules (`terraform-rules`, `kubernetes-rules`, `documentation-rules`)
4. Retrieval guidance

---

## Repository Structure At A Glance

- `docker/`, `compose/`, `local-dev/` — build and local runtime foundations
- `ci/` — CI templates: GitHub Actions, Azure Pipelines, GitLab CI, Jenkins
- `cd/` — deployment targets, Kubernetes base/overlays, Helm, GitOps, Pulumi
- `terraform/` — IaC blueprints for AKS, EKS, GKE, ECS, Lambda
- `ci-security/` — shift-left scanning: SAST, container, secrets, dependency, IaC
- `secops/` — runtime security: Falco, audit logging, supply chain, compliance
- `policy/` — Kyverno admission policies and Conftest static checks
- `secrets/` — External Secrets Operator, secret lifecycle, rotation guides
- `observability/` — Prometheus, Loki, Tempo, OpenTelemetry, SLO assets
- `finops/` — cost governance, rightsizing, reserved capacity, dashboards, optimization loop
- `catalog/` — Git-native service and team registry, validation tooling
- `docs/` — golden paths, guides, ADRs, runbooks

---

## Skill Catalog

Use skills based on task intent:

| Intent | Skill / Prompt |
|--------|---------------|
| Architecture decisions | `.ai/skills/senior-devops-architect/SKILL.md` |
| Cleanup and consistency | `.ai/skills/review-and-refactor/SKILL.md` |
| PR and change risk review | `.ai/skills/code-reviewer/SKILL.md` |
| Learning-focused annotation | `.ai/skills/educational-comments/SKILL.md` |
| Supply chain (signing, SBOM, SLSA) | `.github/prompts/SupplyChainSecurity.prompt.md` |
| Secrets unification or lifecycle | `.github/prompts/UnifiedSecrets.prompt.md` |
| Compliance reporting (SOC 2, CIS, ISO 27001) | `.github/prompts/ComplianceAsCode.prompt.md` |
| Multi-cluster or fleet management | `.github/prompts/MultiClusterFleet.prompt.md` |
| SLO definitions and burn-rate alerting | `.github/prompts/SLODrivenDevelopment.prompt.md` |
| Service registration and ownership | `.github/prompts/ServiceCatalog.prompt.md` |
| FinOps optimization loop | `.github/prompts/FinOpsOptimizationLoop.prompt.md` |

---

## How Agents Should Operate

- Start with canonical retrieval files in `.ai/retrieval/`.
- Route by task intent before opening deep implementation files.
- Prefer golden paths in `docs/golden-paths/` over ad hoc patterns.
- For production-impacting tasks, include security, policy, and FinOps guardrails.
- Keep edits minimal, explicit, and aligned to established templates.
- Consult session summaries in `.ai/session/` before starting multi-step tasks.

---

## Quick Task Routing

| Task | Start Here |
|------|-----------|
| Containerize an app | `docker/`, `compose/` |
| Set up CI pipeline | `ci/<platform>/` |
| Deploy to cloud | `cd/targets/<cloud>/`, `terraform/<cloud>/` |
| Deploy to Kubernetes | `cd/kubernetes/`, `cd/helm/`, `cd/gitops/` |
| Security scanning | `ci-security/`, `policy/` |
| Runtime security / incident | `secops/runbooks/`, `docs/runbooks/` |
| Observability / alerting | `observability/`, `notifications/` |
| SLO definition and alerting | `observability/prometheus/slos/`, `docs/golden-paths/slo-driven-development.md` |
| Cost control / FinOps | `finops/`, `docs/golden-paths/finops-optimization.md` |
| Service ownership / on-call | `catalog/`, `docs/golden-paths/service-catalog.md` |
| Compliance reporting | `secops/compliance/`, `docs/golden-paths/compliance-reporting.md` |
| Architecture decision | `docs/ARCHITECTURE_DECISION_GUIDE.md` |

---

## Session Summary Requirement

- At the end of every completed session, create a session summary file.
- Store in `.ai/session/` using the naming convention `YYYY-MM-DD-topic.md`.
- Refer to prior session summaries to preserve continuity across related tasks.

---

## Review Mode Expectations

When asked to review, prioritize findings in this order:

1. Bugs and regressions
2. Security and policy bypass risks
3. Reliability and operational safety
4. Missing resource limits and cost controls
5. Missing tests and documentation updates

Report findings ordered by severity with concrete file-level remediation.

---

## Authoring and Refactoring Expectations

- Prefer reusable templates over one-off implementations.
- Avoid hardcoded environment values — use variables or external config references.
- Use descriptive names that include scope and target.
- Preserve existing behavior unless change is explicitly requested.
- Update relevant docs and runbooks when behavior or usage changes.

---

## Domain Rules

### Supply Chain

- Always pin `cosign`, `slsa-github-generator`, and `anchore/sbom-action` to specific versions or SHAs — never floating tags. Add `# <-- UPDATE QUARTERLY` on each pin.
- Every `cosign verify` command must include `--certificate-identity-regexp` and `--certificate-oidc-issuer` — bare verify commands are never acceptable.
- Kyverno supply chain policies must match the namespace label convention in `secops/supply-chain/cosign-verify-policy.yaml`. Do not invent new label names.
- New supply chain policies extend existing ones in `secops/supply-chain/` — never replace them.
- OIDC federation (`docs/guides/github-actions-oidc.md`) is a prerequisite before keyless signing will work.

### Secrets

- Never generate content that could expose secret values, even in examples. Use `<SECRET-VALUE>` placeholders.
- The canonical secrets location is `secrets/`. `ci-security/secret-rotation/` is for Terraform-managed rotation only.
- Always reference `secrets/guides/secret-lifecycle.md` when discussing post-rotation rollout in pods.
- `ExternalSecret` refreshInterval: 1h default, 15m high-rotation, 24h stable infrastructure. Add a comment on each explaining the tradeoff.
- Secret naming convention: `/service-name/environment/secret-name`. Enforce in all examples.

### Compliance

- Control YAML files must use the schema defined in `secops/compliance/control-library/soc2-controls.yaml`.
- Evidence collection scripts must never collect actual secret values — only metadata. Add explicit checks and comments.
- Compliance score: `implemented / (total - not_applicable)`, partial = 0.5. Use this formula consistently.
- All new Kyverno policies must include the `secops.requirements` annotation mapping to control IDs — see `secops/supply-chain/cosign-verify-policy.yaml` for the format.
- Always include `--fail-below` on compliance report scripts to enable CI gating.

### Multi-Cluster Fleet

- Fleet topology is configured, not templated — `cluster-registry.yaml` values drive hub-and-spoke, distributed, and hierarchical modes.
- The cluster registry ConfigMap is human-maintained only. Never generate automation that writes to it.
- Scale limit is 20 clusters per fleet ApplicationSet. Include this as a comment.
- `retry.backoff` and `ApplyOutOfSyncOnly: true` are mandatory on all fleet ApplicationSets.
- `finalizers: [resources-finalizer.argocd.argoproj.io]` is mandatory on all fleet Application resources.
- Observability aggregation uses `remote_write` only. Thanos/Cortex are `# <-- UPGRADE PATH` only.
- Fleet policies use Audit mode only. Enforce mode on a workload cluster is a production outage.

### SLO-Driven Development

- Use the multi-window burn-rate model (Google SRE Workbook) exclusively. Four required tiers: 14.4×/1h+5m (critical), 6×/6h+30m (high), 3×/24h+2h (warning), 1×/72h+6h (info). Never deviate.
- Recording rules are mandatory — never compute multi-window ratios directly in alert expressions. Add a comment in every alert file explaining why.
- Recording rule naming convention: `slo:<service>:<metric>:<window>`. Enforce in every generated file.
- `for` durations: 2m (Tier 1), 15m (Tier 2), 1h (Tier 3), 3h (Tier 4). Add a comment on each.
- SLO targets must not exceed the service's measured baseline. Warn against aspirational targets.
- Every SLO definition must have a companion error budget policy file in `docs/slo-policies/`.
- SOC 2 controls CC7.2 and CC7.4 are satisfied by SLO recording rules and alert history. Always include this cross-reference.

### Service Catalog

- The catalog is Git-native — no database, no API server. External portals are `# <-- UPGRADE PATH` only.
- Two-gate enforcement: CI validates via `catalog/scripts/validate-catalog.py --strict`; Kyverno enforces at admission.
- `lifecycle: stable` requires `runbook_url`, `slo.definition_file`, and `cost_center`. `lifecycle: alpha` does not.
- The `name` field must match the `app` label on the Deployment exactly. Add this as a comment on the schema.
- CODEOWNERS must be regenerated after any ownership change: `python catalog/scripts/generate-codeowners.py`.
- Do not suggest Backstage for fewer than 50 services — use `catalog/scripts/migrate-to-backstage.py` when that threshold is reached.
- Ownership discovery commands must appear in every golden path referencing the catalog.

### FinOps Optimization Loop

- The loop covers four types: rightsizing, reserved capacity, anomaly investigation, label compliance. All four must be addressed in every optimization runbook and golden path.
- `generate-optimization-pr.py` enforces safety in code: memory reduction > 50% in one change raises an exception.
- Reserved capacity recommendations must include risk scoring (low/medium/high) based on workload age and resource variance. Never recommend a 3-year commitment for a workload under 3 months old.
- Cross-cloud normalization unit: `(vCPU_hours × $0.048) + (GiB_hours × $0.006)`. Add the approximation disclaimer comment in every normalization script. Mark pricing with `# <-- UPDATE QUARTERLY`.
- Kubecost is the primary data source — scripts must work with Kubecost alone without requiring direct cloud API access.
- Every golden path and runbook for FinOps must end with: "verify savings in the dashboard within 48 hours."
