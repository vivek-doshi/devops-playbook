# Compliance-as-Code

This directory contains reusable templates and automation to demonstrate Kubernetes compliance with SOC 2, CIS Kubernetes Benchmark, and ISO 27001 controls.

## Directory Overview

### Framework mappings (existing markdown)

- [secops/compliance/controls/soc2.md](controls/soc2.md)
- [secops/compliance/controls/cis-kubernetes.md](controls/cis-kubernetes.md)
- [secops/compliance/controls/iso27001.md](controls/iso27001.md)

### Machine-readable control libraries (new)

- [secops/compliance/control-library/soc2-controls.yaml](control-library/soc2-controls.yaml)
- [secops/compliance/control-library/cis-kubernetes.yaml](control-library/cis-kubernetes.yaml)
- [secops/compliance/control-library/iso27001.yaml](control-library/iso27001.yaml)
- [secops/compliance/control-library/control-to-policy-map.yaml](control-library/control-to-policy-map.yaml)

### Evidence and reporting pipeline (new)

- [secops/compliance/scripts/collect-evidence.sh](scripts/collect-evidence.sh)
- [secops/compliance/scripts/generate-compliance-report.py](scripts/generate-compliance-report.py)
- [secops/compliance/kubernetes/compliance-report-cronjob.yaml](kubernetes/compliance-report-cronjob.yaml)
- [secops/compliance/alerts/compliance-alerts.yaml](alerts/compliance-alerts.yaml)

### Scanner jobs (existing)

- [secops/compliance/kube-bench-job.yaml](kube-bench-job.yaml)
- [secops/compliance/kube-bench-cronjob.yaml](kube-bench-cronjob.yaml)

### Golden path (new)

- [docs/golden-paths/compliance-reporting.md](../../docs/golden-paths/compliance-reporting.md)

## Compliance Score

The compliance score is computed as:

- `implemented / (total - not_applicable)`
- `partial` contributes `0.5`

Recommended targets:

- `>90%` for production clusters handling sensitive data
- `>80%` for standard production clusters
- `>70%` for development clusters

Use CI gating with:

```bash
python secops/compliance/scripts/generate-compliance-report.py \
  --evidence-dir ./evidence-YYYYMMDD \
  --fail-below 0.80
```
