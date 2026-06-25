# CI Security Scanning Templates

This folder provides shift-left security controls for pull requests and merge pipelines.

## Purpose

Use `ci-security/` to detect security issues before deployment.

## What's Inside

- `sast/`: Static analysis templates.
- `container-scanning/`: Image vulnerability scanning.
- `secret-detection/`: Secret leak detection.
- `dependency-audit/`: Dependency vulnerability checks.
- `iac-scanning/`: Terraform and IaC misconfiguration scanning.
- `secret-rotation/`: Rotation workflow templates.

## Use This Component Alone

- Add one scanner to an existing CI workflow.
- Run periodic deep scans on schedules.

## Use This Component With Others

- With `ci/`: Add security gates to every pull request.
- With `secops/`: Escalate findings into runtime controls and incident workflows.
- With `policy/`: Enforce preventive guardrails after shift-left checks.
- With `secrets/`: Move from detection to lifecycle-safe remediation.

## Recommended Scan Cadence

1. Every PR: SAST and secret detection.
2. Every main merge: full image and dependency scans.
3. Weekly: deep scan across all critical workloads.
