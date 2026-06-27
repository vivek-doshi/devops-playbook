# Policy

This folder contains policy-as-code resources for preventive governance.

## Purpose

Use `policy/` to enforce non-negotiable security and operational standards before and during deployment.

## What's Inside

- `conftest/`: static policy checks for CI pipelines.
- `kyverno/`: admission policies for Kubernetes runtime enforcement.

## Use This Component Alone

- Validate manifests in CI with Conftest.
- Enforce cluster guardrails with Kyverno.

## Use This Component With Others

- With `ci/` and `ci-security/`: fail pull requests on policy violations.
- With `cd/`: enforce deployment-time and runtime controls.
- With `catalog/` and `finops/`: enforce ownership and cost-governance requirements.
- With `secops/`: align policy enforcement and compliance evidence.

## Policy Lifecycle

1. Start in audit mode.
2. Measure violations and remediation effort.
3. Move to enforce mode for stable controls.
4. Document policy intent in guides and ADRs.
