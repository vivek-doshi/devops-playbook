# SecOps

This folder provides runtime security, compliance automation, and security incident guidance.

## Purpose

Use `secops/` to operate security controls after deployment and maintain auditable evidence.

## What's Inside

- `runtime/`: Falco and audit logging integrations.
- `supply-chain/`: image signing and attestation verification policies.
- `compliance/`: control libraries, scan jobs, and evidence mappings.
- `runbooks/`: incident response procedures.

## Use This Component Alone

- Deploy one runtime control set.
- Run one compliance scan and archive results.

## Use This Component With Others

- With `ci-security/`: carry findings from pre-deploy scans into runtime controls.
- With `policy/`: enforce admission and runtime requirements consistently.
- With `observability/` and `notifications/`: centralize detection and alert routing.
- With `secrets/`: execute incident remediation for exposed credentials.

## Typical Adoption Flow

1. Enable supply-chain verification policies.
2. Deploy runtime detection and audit logging.
3. Configure alert routing and runbook references.
4. Schedule compliance scans and collect evidence.
