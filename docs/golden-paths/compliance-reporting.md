# Golden Path - Compliance Reporting

> **An opinionated, end-to-end workflow that guides developers from idea -> production**

---

## When to use this path

- You need to demonstrate compliance for SOC 2, CIS Kubernetes Benchmark, or ISO 27001.
- You are preparing for an audit, customer questionnaire, or internal governance review.
- You need repeatable, machine-generated evidence rather than ad hoc screenshots.

Not the right path? See [platform-onboarding.md](platform-onboarding.md) Step 7 if you only need Kyverno installation without full compliance reporting automation.

---

## Prerequisites

Run the environment checker before implementation:

```bash
bash scripts/env-checker.sh
```

Required baseline:
- `kubectl` access to target cluster
- `jq` available for evidence parsing
- Python 3 with `pyyaml` installed for report generation

---

## Flow

```text
apply control library -> install kube-bench CronJob -> install compliance CronJob
-> evidence collection runs weekly -> generate report -> review score
-> address gaps -> graduate failing controls to implemented
-> submit evidence package to auditor
```

---

## Step 1 - Review control library and identify gaps

Start with control mappings in [secops/compliance/control-library/](../../secops/compliance/control-library/):

- [secops/compliance/control-library/soc2-controls.yaml](../../secops/compliance/control-library/soc2-controls.yaml)
- [secops/compliance/control-library/cis-kubernetes.yaml](../../secops/compliance/control-library/cis-kubernetes.yaml)
- [secops/compliance/control-library/iso27001.yaml](../../secops/compliance/control-library/iso27001.yaml)

---

## Step 2 - Install kube-bench scheduled scanning

Apply the existing scanner schedule in [secops/compliance/kube-bench-cronjob.yaml](../../secops/compliance/kube-bench-cronjob.yaml):

```bash
kubectl apply -f secops/compliance/kube-bench-cronjob.yaml
```

---

## Step 3 - Install compliance reporter pipeline

Apply [secops/compliance/kubernetes/compliance-report-cronjob.yaml](../../secops/compliance/kubernetes/compliance-report-cronjob.yaml):

```bash
kubectl apply -f secops/compliance/kubernetes/compliance-report-cronjob.yaml
```

---

## Step 4 - Run first evidence collection manually

```bash
bash secops/compliance/scripts/collect-evidence.sh --output-dir ./evidence-bootstrap
```

---

## Step 5 - Generate first compliance report

```bash
python secops/compliance/scripts/generate-compliance-report.py \
  --control-library-dir secops/compliance/control-library \
  --evidence-dir ./evidence-bootstrap \
  --format markdown
```

Use `--fail-below` for CI gating when score must meet policy:

```bash
python secops/compliance/scripts/generate-compliance-report.py \
  --control-library-dir secops/compliance/control-library \
  --evidence-dir ./evidence-bootstrap \
  --fail-below 0.85
```

---

## Step 6 - Review score and failing checks

Inspect summary score and `failing_automated_checks` in the report output.

---

## Step 7 - Address gaps with control-to-policy map

Use [secops/compliance/control-library/control-to-policy-map.yaml](../../secops/compliance/control-library/control-to-policy-map.yaml) to locate policy remediations by framework/control.

---

## Step 8 - Deploy compliance alerts

Apply [secops/compliance/alerts/compliance-alerts.yaml](../../secops/compliance/alerts/compliance-alerts.yaml):

```bash
kubectl apply -f secops/compliance/alerts/compliance-alerts.yaml
```

---

## Step 9 - Schedule quarterly evidence package submission

Package `report.json` and `manifest.json` from each quarter for auditor handoff. Keep the package immutable after submission.

---

## Gap Remediation Guide

| Common failing control | Remediation file |
|---|---|
| Unsigned image admission failures (CIS 5.5.1, SOC2 CC6.8) | [secops/supply-chain/cosign-verify-policy.yaml](../../secops/supply-chain/cosign-verify-policy.yaml) |
| Missing SBOM attestation (SOC2 CC6.8, ISO 8.28) | [secops/supply-chain/sbom-policy.yaml](../../secops/supply-chain/sbom-policy.yaml) |
| Missing provenance attestation (ISO 8.4) | [secops/supply-chain/slsa-verify.yaml](../../secops/supply-chain/slsa-verify.yaml) |
| Non-root/resource policy violations (CIS 5.2.x) | [policy/kyverno/require-non-root.yaml](../../policy/kyverno/require-non-root.yaml) |
| Missing resource limits (SOC2 CC8.1) | [policy/kyverno/require-resource-limits.yaml](../../policy/kyverno/require-resource-limits.yaml) |
| Network segmentation gaps (CIS 5.3.x) | [cd/kubernetes/_base/network-policies/](../../cd/kubernetes/_base/network-policies/) |

---

## Guardrails

| Rule | Enforced by |
|---|---|
| Evidence collection never captures secret values | `collect-evidence.sh` metadata-only ExternalSecret extraction + explicit comments |
| Compliance score alerts notify before audit windows | `compliance-alerts.yaml` score and staleness alerts |
| Control mappings are machine-readable and versioned | `secops/compliance/control-library/*.yaml` |
| Weekly evidence generation is automated | `compliance-report-cronjob.yaml` schedule |
| CI can gate compliance regressions | `generate-compliance-report.py --fail-below` |

---

## Responsibilities

| Role | Owns |
|---|---|
| Developer | Fixes failing control implementations in workload/policy templates |
| Platform team | Maintains CronJobs, evidence pipeline, and cluster access controls |
| Security/GRC | Reviews framework mappings, score thresholds, and auditor submissions |
