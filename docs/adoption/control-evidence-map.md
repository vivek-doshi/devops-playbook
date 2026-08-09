---
Last reviewed: 2026-06-27
Owner: Platform team
---

# Control Evidence Map - SOC 2 / ISO 27001 / CIS Kubernetes Benchmark

Audience: GRC/Security teams, external auditors, CISO.

Purpose: Map control intent to implementation assets and evidence artifacts that can be collected repeatedly.

## Section 1 - SOC 2 Type II (Trust Services Criteria)

| Control ID | Control Name | Implementation asset | Evidence artifact | Automated? | Collection script | Gap / Note |
|---|---|---|---|---|---|---|
| CC6.1 | Logical access controls | `cd/kubernetes/_base/rbac/`, `policy/kyverno/require-non-root.yaml` | RBAC manifests, Kyverno PolicyReport output | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add recurring RBAC review attestation workflow |
| CC6.6 | Logical access reviewed | `catalog/teams/`, `catalog/scripts/generate-codeowners.py` | CODEOWNERS diffs, PR review logs | Partial | `secops/compliance/scripts/collect-evidence.sh` | Formal quarterly access review checklist should be added |
| CC6.7 | Transmission encryption | `cd/kubernetes/cert-manager/`, `docs/ARCHITECTURE_DECISION_GUIDE.md` | Certificate and issuer resources, ingress TLS config | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add explicit TLS minimum version policy evidence |
| CC6.8 | Prevention of unauthorized software | `secops/supply-chain/cosign-verify-policy.yaml`, `secops/supply-chain/sbom-policy.yaml`, `secops/supply-chain/slsa-verify.yaml` | `cosign verify` logs, admission PolicyReports | Yes | `secops/compliance/scripts/collect-evidence.sh` | Enforce mode must be confirmed per production namespace |
| CC7.2 | System monitoring | `observability/prometheus/`, `observability/prometheus/recording-rules/` | Alert history, burn-rate recordings | Yes | `secops/compliance/scripts/collect-evidence.sh` | Ensure all services have SLO definitions |
| CC7.4 | Detection and response | `docs/golden-paths/incident-response.md`, `docs/runbooks/` | Incident timeline, runbook links, escalation records | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add standardized PIR template evidence |
| CC8.1 | Change management | `ci/github-actions/`, `cd/gitops/`, `docs/guides/branching-strategy.md` | PR approvals, CI logs, deployment diffs | Yes | `secops/compliance/scripts/collect-evidence.sh` | `.github/workflows/repo-quality.yml` must be present in adopting repos |
| A1.2 | Recovery procedures | `docs/guides/disaster-recovery.md`, `backup/velero/` | Backup schedules, restore drill records | Partial | `secops/compliance/scripts/collect-evidence.sh` | Require periodic restore drill evidence attachment |

### SOC 2 Gaps

| Priority | Gap | Risk | Recommended implementation path |
|---|---|---|---|
| 1 | No standardized quarterly logical access attestation package | High | Add access-review runbook under `docs/runbooks/` and attach evidence in `secops/compliance/evidence/` |
| 2 | PIR evidence consistency varies by service | Medium | Introduce PIR template in `docs/runbooks/` and require link in incident close workflow |
| 3 | Production enforcement attestation for supply chain controls not centralized | Medium | Add namespace-level enforcement status export in `secops/compliance/scripts/collect-evidence.sh` |

## Section 2 - ISO 27001:2022 (Annex A Controls)

| Control ID | Control Name | Implementation asset | Evidence artifact | Automated? | Collection script | Gap / Note |
|---|---|---|---|---|---|---|
| A.8.2 | Privileged access rights | `cd/kubernetes/_base/rbac/`, `catalog/teams/` | RBAC role bindings, ownership records | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add formal approval trail for elevated role grants |
| A.8.4 | Access to source code | `docs/guides/branching-strategy.md`, `ci/github-actions/` | Branch protection and PR review logs | Partial | `secops/compliance/scripts/collect-evidence.sh` | Include branch protection export in evidence pack |
| A.8.7 | Protection against malware | `ci-security/container-scanning/`, `ci-security/dependency-audit/` | Scan reports and remediation logs | Yes | `secops/compliance/scripts/collect-evidence.sh` | Track closure SLA for critical findings |
| A.8.8 | Management of technical vulnerabilities | `ci-security/sast/`, `ci-security/dependency-audit/`, `docs/golden-paths/incident-response.md` | SAST/SCA trend reports, incident tickets | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add vulnerability aging dashboard reference |
| A.8.9 | Configuration management | `terraform/`, `cd/gitops/`, `policy/` | IaC plans, GitOps diffs, policy validation results | Yes | `secops/compliance/scripts/collect-evidence.sh` | Validate non-IaC emergency changes are documented |
| A.8.12 | Data leakage prevention (secrets) | `secrets/external-secrets/`, `secrets/guides/secret-lifecycle.md`, `ci-security/secret-detection/` | ExternalSecret metadata, secret scan results | Yes | `secops/compliance/scripts/collect-evidence.sh` | Add secret rotation completion attestation |
| A.8.25 | Secure development lifecycle | `docs/golden-paths/`, `ci/`, `quality/` | Golden path adoption and CI quality gate logs | Partial | `secops/compliance/scripts/collect-evidence.sh` | Ensure every service follows a named golden path |
| A.8.28 | Secure coding | `quality/`, `ci-security/sast/`, `docs/guides/pre-commit-setup.md` | Lint/SAST reports and pre-commit usage | Yes | `secops/compliance/scripts/collect-evidence.sh` | Add secure-coding training evidence path |
| A.8.29 | Security testing in development and acceptance | `ci-security/`, `quality/`, `docs/golden-paths/compliance-reporting.md` | CI test/scanning outputs | Yes | `secops/compliance/scripts/collect-evidence.sh` | Add periodic adversarial test cadence for critical services |

### ISO 27001 Gaps

| Priority | Gap | Risk | Recommended implementation path |
|---|---|---|---|
| 1 | Elevated access approval and recertification evidence incomplete | High | Add quarterly privileged access review workflow and artifact export |
| 2 | Vulnerability remediation SLA evidence not uniformly captured | Medium | Extend compliance report with aging/SLA fields from scan results |
| 3 | Security testing beyond CI static checks is limited | Medium | Add recurring dynamic or scenario-based security testing runbook |

## Section 3 - CIS Kubernetes Benchmark v1.8

| Control ID | Control Name | Implementation asset | Evidence artifact | Automated? | Collection script | Gap / Note |
|---|---|---|---|---|---|---|
| 5.2.x | Pod Security Standards | `policy/kyverno/require-non-root.yaml`, `policy/kyverno/require-readonly-filesystem.yaml`, `policy/kyverno/require-resource-limits.yaml` | PolicyReports and admission events | Yes | `secops/compliance/scripts/collect-evidence.sh` | Ensure all workloads are mapped to policy exceptions where needed |
| 5.3.x | Network policies | `cd/kubernetes/_base/network-policies/` | NetworkPolicy manifests and namespace coverage report | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add deny-all coverage validation per namespace |
| 5.5.1 | Images are signed and verified | `secops/supply-chain/cosign-verify-policy.yaml` | Admission reports and signature verification logs | Yes | `secops/compliance/scripts/collect-evidence.sh` | Enforce mode verification needed for production namespaces |
| 5.7.x | Namespace and tenancy boundaries | `cd/kubernetes/_base/rbac/`, `docs/golden-paths/platform-onboarding.md` | Namespace RBAC manifests and onboarding records | Partial | `secops/compliance/scripts/collect-evidence.sh` | Add tenant boundary conformance report |
| 4.2.x | API server and controller manager hardening | `docs/guides/kubernetes-security-checklist.md`, `secops/compliance/kube-bench-cronjob.yaml` | kube-bench scan output | Yes | `secops/compliance/scripts/collect-evidence.sh` | Managed control-plane specifics vary by cloud provider |
| 1.x/2.x | Control plane and etcd baseline controls | `secops/compliance/kube-bench-cronjob.yaml` | kube-bench findings and trend reports | Yes | `secops/compliance/scripts/collect-evidence.sh` | Some controls depend on cloud-managed defaults and require documented compensating controls |

### CIS Kubernetes Gaps

| Priority | Gap | Risk | Recommended implementation path |
|---|---|---|---|
| 1 | Namespace-level deny-all and exception coverage reporting is incomplete | High | Add namespace policy coverage report job under `secops/compliance/scripts/` |
| 2 | Multi-cluster CIS status consolidation is not standardized | Medium | Publish per-cluster benchmark rollup in compliance report pipeline |
| 3 | Tenant boundary attestations are manual | Medium | Add automated RBAC and namespace boundary evidence snapshots |

## Evidence Collection Integration

```bash
# Collect evidence for SOC 2 CC6.8 (supply chain)
bash secops/compliance/scripts/collect-evidence.sh \
  --control CC6.8 \
  --output-dir ./evidence/$(date +%Y-Q%q)
```

For full pipeline flow, see `docs/golden-paths/compliance-reporting.md`.
