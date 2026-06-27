---
Last reviewed: 2026-06-27
Owner: Platform team
---

# Policy Exception and Waiver Process

Audience: Application team leads, platform engineers, SecOps/GRC.

This process ensures exceptions are explicit, time-boxed, and auditable. It applies to policy bypasses that are operationally necessary but must not become permanent control gaps.

## Scope

In scope:
- Kyverno admission policy exceptions.
- CI quality gate suppressions such as `.gitleaks.toml` allowlist entries.
- Checkov suppressions using `#checkov:skip=<RULE>:<justification>`.
- FinOps cost-label enforcement suppressions.

Out of scope:
- Security incidents and incident response actions.
- Infrastructure-level cloud policy exceptions managed by cloud security governance.

## Exception Categories

| Category | Example | Max duration | Approver |
|---|---|---|---|
| Temporary (implementation in-flight) | Legacy service does not yet define resource limits | 30 days | Platform team lead |
| Vendor constraint | Third-party image must run as root | 90 days, renewable | Platform lead + CISO |
| Architecture exception | Service requires writable filesystem for legitimate runtime behavior | 6 months | Eng Lead + CISO |
| Permanent waiver | Regulatory requirement conflicts with policy intent | Annual review | VP Eng + CISO |

## Process Steps

1. Request.
Open a PR adding `docs/adoption/exceptions/YYYY-<service>-<policy>.md` using the template in Appendix A.

2. Triage.
Platform team reviews within 2 business days and confirms whether this is a real constraint or implementation debt.

3. Risk assessment.
SecOps/GRC scores risk using the scoring table below.

4. Approval.
Approver signs off according to category matrix. Approval is captured as PR approval on the exception record.

5. Implementation.
Platform or owning team applies bypass mechanism with justification:
- Kyverno: namespace exclusion label or policy-scoped exclusion.
- Gitleaks: `.gitleaks.toml` `[allowlist]` entry with rationale.
- Checkov: inline skip with explicit justification.

6. Tracking.
Add record to `docs/adoption/exceptions/registry.yaml`.

7. Expiry monitoring.
Weekly CI must run `scripts/check-exception-expiry.sh` and open an issue when expiry is within 7 days.

8. Renewal or close.
Exception owner either removes bypass and closes record or submits renewal through the same PR process.

Implementation note:
- `scripts/check-exception-expiry.sh` is referenced by this process and should be created as part of rollout hardening.

## Risk Scoring Table

Score each factor from 1 to 3.

| Factor | 1 (Low) | 2 (Medium) | 3 (High) |
|---|---|---|---|
| Attack surface exposure | Internal-only, tightly scoped | Internal + limited external adjacency | Publicly reachable or broad trust boundary |
| Data sensitivity | Public/non-sensitive | Internal business data | Regulated or high-impact confidential data |
| Blast radius | Single non-critical service | One domain or shared dependency | Multi-service or production-wide impact |
| Compensating controls present | Multiple controls verified | Partial controls present | No meaningful compensating controls |
| Time to remediation | <= 2 weeks | 2-8 weeks | > 8 weeks |

Interpretation:
- Total score range: 5-15.
- Score >= 10 requires CISO approval regardless of category.

## Audit Trail

All exception records in `docs/adoption/exceptions/` are versioned in Git and reviewed through pull requests.

`docs/adoption/exceptions/registry.yaml` is the canonical registry artifact and can be consumed by `secops/compliance/scripts/collect-evidence.sh` in compliance evidence workflows.

## Appendix A - Exception PR Template

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
