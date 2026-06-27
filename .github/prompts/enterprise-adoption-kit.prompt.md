---
mode: agent
model: claude-sonnet-4-6
tools:
  - read_file
  - create_file
description: >
  Generate the Enterprise Adoption Kit — a structured set of documents under
  docs/adoption/ that gives platform teams, engineering leadership, and GRC teams
  everything they need to roll out this playbook at organizational scale.
  Covers maturity model, 30/60/90 day plan, platform operating model, RACI,
  exception/waiver process, and compliance control evidence mapping.
---

# Prompt: Enterprise Adoption Kit

## TEMPLATE

You are acting as the principal platform engineer responsible for scaling this playbook
across an organization of 50–500 engineers. Your task is to produce the full
`docs/adoption/` directory with all documents required for enterprise rollout.

These documents are consumed by: platform team leads, engineering managers, CTO/VP Eng,
security/GRC teams, and application team leads. Write for a technical-but-non-operational
audience except where command-line procedures are needed.

---

## WHEN TO USE

Invoke this prompt when:
- The organization is ready to move from "pilot team" to "org-wide rollout"
- A GRC or audit team asks for control evidence mapping to SOC 2 / ISO 27001 / CIS
- Engineering leadership asks for a structured 90-day rollout plan
- Platform team needs a formal exception/waiver process before enforcing Kyverno policies
- A new platform team lead joins and needs to understand operating model and accountabilities

---

## PREREQUISITES

Before generating files, read:
- `docs/decisions/ADR-001-folder-structure.md` — understand domain intent
- `docs/decisions/ADR-004-policy-enforcement-layering.md` — understand layered controls
- `docs/decisions/ADR-005-slo-driven-operations-standard.md` — understand reliability standard
- `docs/golden-paths/platform-onboarding.md` — understand onboarding flow
- `docs/golden-paths/compliance-reporting.md` — understand evidence pipeline
- `secops/compliance/control-library/` directory listing — understand existing control structure

---

## MATURITY

**Stable** — these are living governance documents. Tag each file with a `Last reviewed:`
frontmatter field and schedule quarterly review as part of the SLO quarterly review cadence.

---

## GENERATION INSTRUCTIONS

Generate all seven files below. Each file is a standalone Markdown document.
Create `docs/adoption/README.md` as the index after the others are complete.

---

### FILE 1 — `docs/adoption/maturity-model.md`

Title: **Platform Maturity Model — Crawl / Walk / Run**

Structure the model across five domains with three maturity levels each.
Domains: CI/CD, Security & Supply Chain, Observability & SLOs, FinOps, Platform Governance.

For each domain × level cell, include:
- What "done" looks like (2–3 bullet outcomes)
- Which playbook assets enable it (exact file paths)
- Recommended timeline hint

**Crawl (weeks 1–4):** Highest-ROI basics only. No new tooling beyond what ships in this repo.
**Walk (weeks 5–12):** Automation, enforcement, and feedback loops operational.
**Run (month 4+):** Self-service, policy-as-code enforced, SLO-driven operations standard.

Include a "Where is your team today?" self-assessment table: 5 yes/no questions per domain
that produce a crawl/walk/run placement. Make it fillable as a Markdown checklist.

Mapping table at the bottom cross-referencing maturity level → golden path → ADR.

---

### FILE 2 — `docs/adoption/30-60-90-plan.md`

Title: **30 / 60 / 90 Day Platform Rollout Plan**

Audience: Platform team lead + Engineering VP sponsoring the rollout.

Structure: three phases, each with a table of tasks.

**Days 1–30 — Foundation (Crawl → Walk)**

| # | Task | Owner | Outcome | Playbook reference |
|---|---|---|---|---|

Tasks must include:
- Platform team formation and operating model agreement (→ FILE 3)
- Service registry bootstrap: register top 10 production services in `catalog/`
- `scripts/env-checker.sh` run on all platform engineers' machines
- Kind cluster standing up and verified on 100% of platform team machines
- Pre-commit hooks installed and enforced on all platform repos
- OIDC federation configured for top 3 cloud accounts in use
- Remote Terraform state bootstrapped for prod cloud account
- At least one golden path end-to-end validated (recommend: Kubernetes Microservice)
- Kyverno installed on non-production cluster in Audit mode
- Prometheus stack deployed; at least one SLO defined per pilot service
- Repo quality gate (`.github/workflows/repo-quality.yml`) passing on this playbook fork

**Days 31–60 — Hardening (Walk)**

Tasks must include:
- Kyverno Audit → Enforce graduation for `require-non-root` and `require-resource-limits` on non-prod
- ESO deployed; all pilot service secrets migrated off static credentials
- Supply chain: cosign signing and SBOM generation on all pilot service images
- FinOps: cost labels enforced (Audit mode); Kubecost/OpenCost deployed
- Compliance evidence pipeline: `kube-bench` CronJob running; first compliance report generated
- Onboard second application team using platform-onboarding golden path
- Runbooks written for top 3 alert scenarios per pilot service
- SLO quarterly review cadence established and first review scheduled

**Days 61–90 — Scale (Run)**

Tasks must include:
- Kyverno Enforce mode on production cluster for all stable policies
- Supply chain Enforce mode on production namespace
- All production services in service catalog with validated SLO definitions
- FinOps: Enforce mode for cost labels; first rightsizing PR generated and merged
- Exception/waiver process (→ FILE 5) ratified and at least one exception processed end-to-end
- Platform team NPS survey from application teams (target: ≥ 4.0/5.0 "golden path usefulness")
- Disaster recovery drill completed (Velero restore tested in staging)
- ADR backlog: capture top 3 org-specific decisions not covered by existing ADRs

Include a **Risk Register** section at the bottom: 5 common rollout risks with likelihood, impact, and mitigation mapped to specific playbook assets.

---

### FILE 3 — `docs/adoption/platform-team-operating-model.md`

Title: **Platform Team Operating Model**

Audience: Platform team lead, Engineering VP.

Sections:

**Team Topology**
Map the platform team to Team Topologies concepts:
- Platform team as "Platform" team type
- Application teams as "Stream-aligned" teams
- Interaction mode: X-as-a-Service for stable golden paths; Collaboration mode during onboarding windows
- Thickening vs thinning the platform: when to add self-service vs when to pair

**Core Accountabilities**
Table: domain → platform team owns → application team owns → shared.
Domains: cluster lifecycle, golden paths, security policy, secret infrastructure,
observability stack, FinOps tooling, catalog and CODEOWNERS, incident response tooling, DR.

**Platform Roadmap Cadence**
- Quarterly: maturity model review, ADR backlog, golden path gap analysis
- Monthly: SLO review, FinOps optimization loop, policy violation report
- Weekly: standups, PR review SLA (target: < 2 business days for playbook PRs)
- On-demand: exception/waiver decisions (→ FILE 5), new team onboarding

**Inner Loop vs Outer Loop**
- Inner loop: developer laptop → pre-commit → Kind cluster → CI
- Outer loop: PR → CI → staging deploy → production deploy → SLO signal → incident → PIR → ADR update
- Platform team's job: make both loops faster and safer, not manage them directly

**Platform SLAs to Application Teams**
Table: service type → SLA.
Examples: new namespace provisioning < 2 business days; golden path PR review < 2 business days;
incident escalation response < 15 min for SEV-1; new secret store onboarding < 1 week.

**Toil Budget**
Platform team should not spend > 30% of engineering time on undifferentiated toil.
Define what counts as toil vs investment. Monthly toil tracking template (Markdown table).

**On-Call Model**
Platform team carries on-call for: cluster control plane, ESO/secrets infrastructure,
ArgoCD, Prometheus/Alertmanager stack, Kyverno admission webhooks.
Application teams carry on-call for their own services.
Escalation path from application team → platform → cloud vendor.

---

### FILE 4 — `docs/adoption/raci.md`

Title: **RACI Matrix — DevOps / SecOps / FinOps / Application Teams / Leadership**

Audience: All roles. Use this to resolve accountability disputes and onboard new team members.

Roles across the top (columns):
`Platform Eng` | `App Team` | `SecOps / GRC` | `FinOps` | `DBA` | `Eng Lead / Architect` | `CISO / VP Eng`

Activities down the left (rows), grouped by domain:

**CI/CD & Delivery**
- Golden path selection for a new service
- CI workflow implementation and maintenance
- Reusable workflow updates (shared workflows in `ci/github-actions/_shared/`)
- Image registry management
- ArgoCD ApplicationSet management
- GitOps promotion approval (dev → staging → prod)

**Infrastructure & IaC**
- Terraform module authoring (cloud modules under `terraform/`)
- Terraform apply for production clusters
- Remote state backend management
- Cost delta review for Terraform PRs (Infracost)
- Database provisioning and backup configuration

**Security & Supply Chain**
- Kyverno policy authoring
- Kyverno policy graduation (Audit → Enforce)
- Exception/waiver approval (→ FILE 5)
- cosign keyless signing key rotation (N/A — keyless, but OIDC trust policy updates)
- Supply chain policy exceptions
- Security vulnerability triage (container CVEs)
- Incident response IC role
- Post-incident review facilitation

**Secrets & Identity**
- OIDC federation configuration
- ESO ClusterSecretStore management
- Secret rotation policy definition
- Emergency secret rotation execution
- Secret offboarding during service decommission

**Observability & SLOs**
- Prometheus/Loki/Tempo stack upgrades
- SLO definition per service
- Alert rule authoring
- Alert routing configuration (PagerDuty/Slack)
- SLO quarterly review facilitation
- Error budget policy approval

**FinOps**
- Cost label schema (`finops/docs/cost-tagging-schema.md`) updates
- Budget definition and approval (`finops/config/budgets.yaml`)
- Rightsizing PR generation
- Rightsizing PR approval and merge
- Reserved capacity commitment approval
- Monthly chargeback report distribution

**Governance & Compliance**
- Control library maintenance (`secops/compliance/control-library/`)
- Evidence collection scheduling (`compliance-report-cronjob.yaml`)
- Compliance report review before audit
- Auditor communication
- ADR authoring
- ADR ratification
- Exception/waiver final approval

**Platform Onboarding**
- New team onboarding facilitation (platform-onboarding golden path execution)
- Namespace provisioning
- Service catalog registration (new service)
- Runbook authoring (per service)
- CODEOWNERS generation

Use `R` (Responsible), `A` (Accountable), `C` (Consulted), `I` (Informed).
Every row must have exactly one `A`. Flag any row with no `R` as a gap to resolve.

Add a **"How to use this RACI"** section at the top: 3-paragraph explanation of
R/A/C/I semantics with one worked example (e.g., "Kyverno policy graduation").

---

### FILE 5 — `docs/adoption/exception-waiver-process.md`

Title: **Policy Exception and Waiver Process**

Audience: Application team leads, platform engineers, SecOps/GRC.

Context: Some Kyverno policies run in Enforce mode. Some teams will legitimately need
exceptions (legacy workloads, vendor images, compliance edge cases). This document defines
the formal process so exceptions are auditable, time-boxed, and don't become permanent bypass.

**Scope**
What this process covers: Kyverno admission policies, CI quality gate suppressions
(`.gitleaks.toml` allowlist, `#checkov:skip`), FinOps cost-label enforcement suppressions.
What this process does NOT cover: security incidents (use incident-response path),
infrastructure-level cloud policy (handled by Cloud Security team directly).

**Exception Categories**

| Category | Example | Max duration | Approver |
|---|---|---|---|
| Temporary (implementation in-flight) | Legacy service doesn't set resource limits yet | 30 days | Platform team lead |
| Vendor constraint | Third-party image must run as root | 90 days, renewable | Platform lead + CISO |
| Architecture exception | Service legitimately needs writable filesystem | 6 months | Eng Lead + CISO |
| Permanent waiver | Regulatory requirement incompatible with policy | Annual review | VP Eng + CISO |

**Process Steps**

1. **Request** — Application team opens a PR to `docs/adoption/exceptions/YYYY-<service>-<policy>.md`
   using the template in FILE 5 appendix.
2. **Triage** — Platform team reviews within 2 business days. Validates: is this a real
   constraint or a missing implementation?
3. **Risk assessment** — SecOps/GRC scores risk using the risk scoring table below.
4. **Approval** — Approver signs off based on category table above. Approval is recorded
   as a PR approval on the exception document.
5. **Implementation** — Platform team adds the technical bypass:
   - Kyverno: `kyverno.io/exclude` annotation or namespace label
   - Gitleaks: `.gitleaks.toml` `[allowlist]` entry with justification comment
   - Checkov: `#checkov:skip=<RULE>:<justification>` inline
6. **Tracking** — Exception added to `docs/adoption/exceptions/registry.yaml`
7. **Expiry** — Automated CI check (`scripts/check-exception-expiry.sh`) runs weekly
   and opens a GitHub issue when an exception is within 7 days of expiry.
8. **Renewal or close** — Exception owner either closes the gap (removes bypass) or
   initiates renewal through the same PR process.

**Risk Scoring Table**
Five factors, each scored 1–3: Attack surface exposure | Data sensitivity | Blast radius |
Compensating controls present | Time to remediation. Score ≥ 10 requires CISO approval.

**Exception PR Template** (appendix inline)

```markdown
# Policy Exception Request

| Field | Value |
|---|---|
| Service | |
| Policy | |
| Kyverno policy file | |
| Requested by | |
| Date | |
| Expiry date | |
| Category | Temporary / Vendor constraint / Architecture / Permanent waiver |
| Risk score | /15 |

## Business justification

## Technical constraint

## Compensating controls

## Remediation plan (for Temporary/Vendor categories)

## Approver sign-off
```

**Audit Trail**
All exceptions committed to `docs/adoption/exceptions/` are versioned in Git.
The `registry.yaml` file is the audit artifact consumed by compliance evidence collection
(`secops/compliance/scripts/collect-evidence.sh`).

---

### FILE 6 — `docs/adoption/control-evidence-map.md`

Title: **Control Evidence Map — SOC 2 / ISO 27001 / CIS Kubernetes Benchmark**

Audience: GRC/Security team, external auditors, CISO.

Purpose: Map every material control in the three frameworks to the specific playbook asset
that provides evidence of implementation. This is the "show your work" document for audits.

Format: one table per framework. Columns: Control ID | Control Name | Implementation asset
(exact file path) | Evidence artifact | Automated? | Collection script | Gap / Note.

**Section 1 — SOC 2 Type II (Trust Services Criteria)**

Cover all CC6.x (Logical Access), CC7.x (System Operations), CC8.x (Change Management),
and A1.x (Availability) criteria that are relevant to a Kubernetes-hosted SaaS.

Key mappings to include (generate the full table, these are examples):

| Control | Implementation | Evidence artifact |
|---|---|---|
| CC6.1 — Logical access controls | `cd/kubernetes/_base/rbac/`, `policy/kyverno/require-non-root.yaml` | `kubectl get policyreport -A` output |
| CC6.6 — Logical access reviewed | `catalog/teams/`, CODEOWNERS | PR audit log |
| CC6.7 — Transmission encryption | `cd/kubernetes/cert-manager/`, `docs/ARCHITECTURE_DECISION_GUIDE.md §12` | cert-manager Certificate resources |
| CC6.8 — Prevention of unauthorized software | `secops/supply-chain/cosign-verify-policy.yaml`, `secops/supply-chain/sbom-policy.yaml` | `cosign verify` output, PolicyReport |
| CC7.2 — System monitoring | `observability/prometheus/`, SLO recording rules | Alertmanager alert history |
| CC7.4 — Detection and response | `docs/golden-paths/incident-response.md`, runbooks | PagerDuty incident log |
| CC8.1 — Change management | Branch protection, PR required, CI gate | GitHub audit log |
| A1.2 — Recovery procedures | `docs/guides/disaster-recovery.md`, `backup/velero/` | Velero backup schedule output |

**Section 2 — ISO 27001:2022 (Annex A Controls)**

Cover A.8 (Technology Controls) subclauses most relevant to platform engineering:
A.8.2 (privileged access), A.8.4 (source code), A.8.7 (malware protection),
A.8.8 (vulnerability management), A.8.9 (configuration management),
A.8.12 (data leakage prevention — secrets), A.8.25 (secure development lifecycle),
A.8.28 (secure coding), A.8.29 (security testing in dev/acceptance).

**Section 3 — CIS Kubernetes Benchmark v1.8**

Cover all Level 1 controls plus Level 2 controls that are enforced by existing playbook assets.

Map CIS controls to Kyverno policies:
- CIS 5.2.x (Pod Security Standards) → `policy/kyverno/require-non-root.yaml`, `require-resource-limits.yaml`
- CIS 5.3.x (Network Policies) → `cd/kubernetes/_base/network-policies/`
- CIS 5.5.1 (Signed images) → `secops/supply-chain/cosign-verify-policy.yaml`
- CIS 5.7.x (Namespace boundaries) → RBAC templates, namespace-per-tenant pattern

**Gap Analysis Section**

After each framework table, include a "Gaps" sub-section: controls with no current
playbook implementation, ordered by risk. Provide a recommended implementation path
for the top 3 gaps per framework.

**Evidence Collection Integration**

Add a code block showing how to run the existing evidence collection script with
the new control IDs mapped:

```bash
# Collect evidence for SOC 2 CC6.8 (supply chain)
bash secops/compliance/scripts/collect-evidence.sh \
  --control CC6.8 \
  --output-dir ./evidence/$(date +%Y-Q%q)
```

Cross-reference: `docs/golden-paths/compliance-reporting.md` for the full evidence pipeline.

---

### FILE 7 — `docs/adoption/README.md`

Title: **Enterprise Adoption Kit**

A one-page index document. Sections:

**What this kit is**
Two-paragraph explanation. The playbook ships golden paths for *building* things.
This kit ships golden paths for *adopting the playbook* at organizational scale.

**Who reads what**

| Role | Start here |
|---|---|
| Platform team lead | maturity-model.md → 30-60-90-plan.md → platform-team-operating-model.md |
| Engineering VP / CTO | maturity-model.md → raci.md → 30-60-90-plan.md (executive summary sections) |
| Application team lead | raci.md → exception-waiver-process.md |
| CISO / Security lead | control-evidence-map.md → exception-waiver-process.md |
| GRC / Audit | control-evidence-map.md → docs/golden-paths/compliance-reporting.md |

**Rollout status tracker** (Markdown checklist format)
One checkbox per major 30/60/90 milestone so teams can track progress in the README itself.

**Keeping this kit current**
- Review cadence: quarterly (align with SLO quarterly review)
- Owner: Platform team lead
- Change process: PR to `docs/adoption/`, review by Eng Lead + GRC

---

## OUTPUT CHECKLIST

Confirm before finishing:

- [ ] All 7 files created under `docs/adoption/`
- [ ] Every file has `Last reviewed: YYYY-MM-DD` frontmatter (set to today's date)
- [ ] Every file has `Owner: Platform team` frontmatter
- [ ] All playbook asset references use exact relative paths (not prose descriptions)
- [ ] RACI matrix has exactly one `A` per row — flag any rows where this isn't true
- [ ] Exception process references `scripts/check-exception-expiry.sh` (note: script needs to be created)
- [ ] Control evidence map references `secops/compliance/scripts/collect-evidence.sh` correctly
- [ ] 30/60/90 plan references the repo-quality-gate workflow (`.github/workflows/repo-quality.yml`)
- [ ] `docs/adoption/exceptions/` directory stub created with a `.gitkeep` and `registry.yaml` template
- [ ] `docs/decisions/README.md` updated to reference that ADRs relate to adoption kit

---

## CROSS-REFERENCES

- Platform onboarding golden path: `docs/golden-paths/platform-onboarding.md`
- Compliance reporting golden path: `docs/golden-paths/compliance-reporting.md`
- SLO quarterly review runbook: `docs/runbooks/slo-quarterly-review.md`
- Compliance control library: `secops/compliance/control-library/`
- Evidence collection script: `secops/compliance/scripts/collect-evidence.sh`
- Kyverno policies: `policy/kyverno/`
- FinOps documentation: `finops/README.md`
- Supply chain golden path: `docs/golden-paths/supply-chain-security.md`
