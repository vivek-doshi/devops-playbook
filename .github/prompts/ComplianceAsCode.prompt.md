---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search', 'runCommands']
description: 'Generate a complete Compliance-as-Code implementation: automated evidence collection pipeline, machine-readable control mappings, compliance reporting CronJob, and a golden path guide — covering SOC 2, CIS Kubernetes Benchmark, and ISO 27001 with evidence artifacts suitable for auditor submission.'
---

# Compliance-as-Code Implementation Generator

You are a senior platform engineer and GRC (Governance, Risk, Compliance) specialist with experience designing audit-ready Kubernetes compliance systems. Your task is to generate a complete Compliance-as-Code implementation for this repository.

## Mandatory context reads (do these before writing any file)

- `secops/compliance/controls/soc2.md` — existing SOC 2 control mapping; your machine-readable version must be semantically equivalent
- `secops/compliance/controls/iso27001.md` — existing ISO 27001 mapping; same requirement
- `secops/compliance/controls/cis-kubernetes.md` — existing CIS mapping; same requirement
- `secops/compliance/kube-bench-job.yaml` — existing CIS benchmark scanner; your CronJob extends this
- `secops/compliance/kube-bench-cronjob.yaml` — existing scheduled scan; your evidence pipeline wraps this
- `policy/kyverno/README.md` — Kyverno policy docs; your compliance mapping references these policies
- `secops/supply-chain/cosign-verify-policy.yaml` — understand the annotation format `secops.requirements: "..."` — your mapping must use the same annotation convention
- `observability/prometheus/alerts/` — understand how alerts are structured; your compliance alerts follow this pattern
- `docs/golden-paths/kubernetes-microservice.md` — mirror the golden path format exactly
- `docs/ARCHITECTURE_DECISION_GUIDE.md` — your output must be consistent with Section 10 "Policy Enforcement"
- `finops/scripts/generate-cost-report.py` — understand the report generation pattern; your compliance report script mirrors this structure
- `.ai/instructions/engineering-principles.md` — apply all principles
- `.ai/instructions/security-rules.md` — apply all security rules

## What you are building

A Compliance-as-Code system with four components:

1. **Machine-readable control library** — JSON/YAML control mappings that link framework controls to concrete implementation files
2. **Evidence collection pipeline** — automated collection, formatting, and storage of audit evidence
3. **Compliance reporting** — scheduled report generation and a Prometheus-alertable compliance score
4. **Golden path** — an end-to-end guide for teams implementing compliance requirements

## Your deliverables

### 1. `secops/compliance/control-library/soc2-controls.yaml`

A machine-readable YAML version of the SOC 2 control mapping currently in `secops/compliance/controls/soc2.md`.

**Structure** (follow this schema exactly for all three frameworks):

```yaml
framework: SOC2-TypeII
version: "2017"
generated: "auto"  # updated by the evidence pipeline
controls:
  - id: CC6.1
    title: "Logical access security software"
    description: "One-sentence description"
    status: implemented  # implemented | partial | not-applicable | planned
    evidence:
      - type: kyverno-policy
        path: policy/kyverno/require-non-root.yaml
        description: "Enforces non-root container execution"
      - type: kyverno-policy
        path: policy/kyverno/disallow-latest-tag.yaml
        description: "Prevents use of unverifiable image versions"
      - type: github-actions-workflow
        path: ci/github-actions/_shared/reusable-security-scan.yml
        description: "Automated security scanning in CI"
      - type: kubernetes-config
        path: cd/kubernetes/_base/rbac/
        description: "RBAC configuration files"
    automated_checks:
      - name: kube-bench-check
        tool: kube-bench
        cis_id: "5.1.1"
        pass_condition: "PASS"
      - name: kyverno-policy-report
        tool: kubectl
        command: "kubectl get policyreport -A -o json"
        pass_condition: ".items[].summary.fail == 0"
    audit_query: |
      # Loki query to pull evidence for this control
      {source="k8s-audit", resource="clusterrolebindings"} | json | verb=~"create|update|patch|delete"
```

Generate complete entries for all controls currently in `secops/compliance/controls/soc2.md`. Every control must have at least one `evidence` entry pointing to a real file in this repo and at least one `automated_checks` entry. Controls not yet implemented must have `status: planned` and a `gap_description` field explaining what is missing.

### 2. `secops/compliance/control-library/cis-kubernetes.yaml`

Machine-readable CIS Kubernetes Benchmark control mapping. Same schema as above. Include entries for the kube-bench IDs already tracked in `secops/compliance/controls/cis-kubernetes.md`. Add `kube-bench-id` as a top-level field on each control alongside the existing `id`.

### 3. `secops/compliance/control-library/iso27001.yaml`

Machine-readable ISO 27001:2022 control mapping. Same schema. Use clause IDs from the existing `secops/compliance/controls/iso27001.md`.

### 4. `secops/compliance/control-library/control-to-policy-map.yaml`

A cross-reference file that maps each Kyverno policy in `policy/kyverno/` to the framework controls it satisfies. This is the authoritative source for the annotation `secops.requirements` already used in `secops/supply-chain/cosign-verify-policy.yaml`.

**Structure**:

```yaml
version: 1
policies:
  - path: policy/kyverno/require-non-root.yaml
    name: require-non-root
    satisfies:
      - framework: SOC2
        controls: ["CC6.1", "CC6.8"]
      - framework: CIS-Kubernetes
        controls: ["5.2.1", "5.2.2"]
      - framework: ISO27001
        controls: ["A.8.15", "A.8.2"]
  - path: policy/kyverno/require-resource-limits.yaml
    ...
```

Cover all policies in `policy/kyverno/` and `secops/supply-chain/`.

### 5. `secops/compliance/scripts/collect-evidence.sh`

A bash script that collects evidence artifacts for a compliance audit. Runs against the current cluster.

**What it collects**:

```bash
# Structure of evidence output directory
evidence/
├── timestamp.txt                    # ISO 8601 timestamp of collection run
├── cluster-info.json                # kubectl cluster-info dump
├── kube-bench/
│   └── results.json                 # Latest kube-bench results
├── kyverno/
│   ├── policy-reports.json          # kubectl get policyreport -A -o json
│   ├── cluster-policies.json        # kubectl get clusterpolicy -o json
│   └── violations.json              # Filtered: only failing results
├── rbac/
│   ├── clusterroles.json
│   ├── clusterrolebindings.json
│   └── roles-per-namespace.json
├── network-policies/
│   └── all-namespaces.json
├── pod-security/
│   └── security-contexts.json       # All running pods' securityContext
├── secrets/
│   └── externalsecrets-status.json  # ESO sync status (no secret values)
└── supply-chain/
    └── policy-reports.json          # Kyverno reports for supply chain policies
```

Script requirements:
- `set -euo pipefail` at top
- Check prerequisites (`kubectl`, `jq`) before running
- Accept `--output-dir` argument (default: `./evidence-$(date +%Y%m%d)`)
- Accept `--namespace` argument to scope collection (default: all namespaces)
- Print progress to stderr, evidence paths to stdout
- Create a `manifest.json` at the end listing every file collected with SHA256 hash — this is the tamper-evident audit trail
- Never collect actual secret values — only metadata (ExternalSecret names, sync status, last sync time)
- Add comment: "Run this before every audit window opens, quarterly at minimum"

### 6. `secops/compliance/scripts/generate-compliance-report.py`

A Python script (mirror the structure of `finops/scripts/generate-cost-report.py`) that reads the collected evidence and generates a compliance report.

**Inputs**: the control library YAML files and an evidence directory from `collect-evidence.sh`

**Output**: a JSON report with this structure:

```json
{
  "generated_at": "ISO8601",
  "cluster": "cluster-name",
  "summary": {
    "total_controls": 0,
    "implemented": 0,
    "partial": 0,
    "planned": 0,
    "not_applicable": 0,
    "score_percent": 0.0
  },
  "frameworks": {
    "SOC2": { "score": 0.0, "controls": [] },
    "CIS-Kubernetes": { "score": 0.0, "controls": [] },
    "ISO27001": { "score": 0.0, "controls": [] }
  },
  "failing_automated_checks": [],
  "evidence_manifest": "path/to/manifest.json"
}
```

**Score calculation**: `implemented / (total - not_applicable)`. Partial counts as 0.5.

Add a `--format` flag: `json` (default) or `markdown` for a human-readable summary table.

Add a `--fail-below` flag: exits with code 1 if the overall score is below the threshold. This enables CI gating.

### 7. `secops/compliance/kubernetes/compliance-report-cronjob.yaml`

A Kubernetes CronJob that runs weekly (Sunday 06:00 UTC) and:
1. Runs `collect-evidence.sh` inside the cluster
2. Runs `generate-compliance-report.py` on the collected evidence
3. Stores the report in a ConfigMap named `compliance-report-latest` in the `secops` namespace
4. Stores the evidence manifest in a ConfigMap named `compliance-evidence-manifest-<date>` (one per run, kept for 90 days via a TTL annotation)
5. Pushes a Prometheus metric `compliance_score{framework="SOC2"}` via the pushgateway if one is configured (add `# <-- CHANGE THIS` on the pushgateway URL)

**Service account**: create a `compliance-reporter` ClusterRole with read-only access to PolicyReports, Pods, NetworkPolicies, ClusterRoles, ClusterRoleBindings, ExternalSecrets — never write access. Reference the `readonly-developer` RBAC pattern from `cd/kubernetes/_base/rbac/`.

**Image**: use a minimal Python + kubectl image. Add `# <-- CHANGE THIS` on the image reference with a note to build this from the repo's own CI pipeline.

Mark MATURITY: Beta in the file header.

### 8. `secops/compliance/alerts/compliance-alerts.yaml`

A PrometheusRule resource (mirror the format of `observability/prometheus/alerts/pod-alerts.yaml`) with:

- `ComplianceScoreCritical` — fires when `compliance_score < 0.70` for 24 hours, severity: critical
- `ComplianceScoreWarning` — fires when `compliance_score < 0.85` for 24 hours, severity: warning
- `ComplianceEvidenceStale` — fires when the compliance report ConfigMap has not been updated in 8 days (missed weekly run), severity: warning
- `KyveryoPolicyViolationsHigh` — fires when Kyverno PolicyReport failure count across all namespaces exceeds 10 for 1 hour, severity: warning

Each alert must have `runbook_url: https://runbooks.example.com/<alert-name>` with `# <-- CHANGE THIS` and a `summary` and `description` annotation using label templating.

### 9. `docs/golden-paths/compliance-reporting.md`

A complete golden path in the exact format of `docs/golden-paths/kubernetes-microservice.md`.

**When to use this path**: teams that need to demonstrate compliance with SOC 2, CIS Kubernetes Benchmark, or ISO 27001 for an audit, a customer questionnaire, or an internal governance review.

**Not the right path**: reference `platform-onboarding.md` Step 7 for teams who only need to install Kyverno without a full compliance reporting pipeline.

**Flow**:
```
apply control library → install kube-bench CronJob → install compliance CronJob
→ evidence collection runs weekly → generate report → review score
→ address gaps → graduate failing controls to implemented
→ submit evidence package to auditor
```

**Steps** (numbered, with exact file references):

1. Review the control library and identify gaps: `secops/compliance/control-library/`
2. Install kube-bench scheduled scanning (already exists): `secops/compliance/kube-bench-cronjob.yaml`
3. Install the compliance reporter: `secops/compliance/kubernetes/compliance-report-cronjob.yaml`
4. Run the first evidence collection manually: `bash secops/compliance/scripts/collect-evidence.sh`
5. Generate the first compliance report: `python secops/compliance/scripts/generate-compliance-report.py`
6. Review the score and failing checks
7. Address gaps using the control-to-policy map: `secops/compliance/control-library/control-to-policy-map.yaml`
8. Deploy compliance alerts: `secops/compliance/alerts/compliance-alerts.yaml`
9. Schedule quarterly evidence package submission

**Gap remediation guide** (table format): maps common failing controls to the file in this repo that fixes them.

**Guardrails table**: evidence collection never captures secret values | `collect-evidence.sh` design, code review | compliance score alerts notify before audit windows | `compliance-alerts.yaml` | etc.

### 10. Update `secops/compliance/` top-level README (create if not exists)

Overview of the compliance directory, linking to:
- The three framework markdown files (existing)
- The three machine-readable YAML files (new)
- The evidence collection script (new)
- The compliance reporter (new)
- The golden path (new)
- The kube-bench jobs (existing)

Include a "compliance score" section explaining what the score means and what targets to aim for: >90% for production clusters handling sensitive data, >80% for standard production, >70% for development clusters.

### 11. Update `GETTING_STARTED.md`

Add under "📖 I want to understand the decisions":

| How do we demonstrate compliance? | [`docs/golden-paths/compliance-reporting.md`](docs/golden-paths/compliance-reporting.md) |

## Style rules

- Machine-readable YAML files must be valid YAML — run `python3 -c "import yaml; yaml.safe_load(open('file.yaml'))"` mentally before finalizing
- Every `automated_checks` command must be a real `kubectl` or `kube-bench` command that would work on a standard cluster — no pseudocode
- The evidence collection script must never write secret values — add explicit checks for this with comments
- The compliance report script must follow the same function structure as `finops/scripts/generate-cost-report.py` (argparse, main function, modular helpers)
- Loki queries in audit_query fields must use the LogQL syntax consistent with `secops/compliance/controls/soc2.md`
- The CronJob must use `restartPolicy: OnFailure` and set `activeDeadlineSeconds` — compliance collection that hangs indefinitely is unacceptable
- All file headers must use the TEMPLATE format from existing secops files
- The golden path must reference concrete file paths — no vague guidance
