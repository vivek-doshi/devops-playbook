# Secrets Management Guide

This guide explains how to manage secrets safely across CI/CD and runtime workloads in this repository.

## Design Principles

1. Never store plaintext secrets in Git.
2. Prefer short-lived identity tokens over static credentials.
3. Separate secret source of truth from application deployment manifests.
4. Rotate secrets on a defined schedule and document emergency rotation.
5. Ensure access is least-privilege and auditable.

## Recommended Patterns by Context

### CI/CD authentication

Preferred approach:
- Use OIDC federation from GitHub Actions (or equivalent CI identity federation).

Fallback approach:
- Use CI secret stores only when federation is not available.

Reference:
- `docs/guides/github-actions-oidc.md`

### Kubernetes runtime secrets

Preferred hierarchy:
1. Secret manager as source of truth (Key Vault, Secrets Manager, Vault).
2. External Secrets Operator for cluster sync.
3. Native Kubernetes Secrets only as synced runtime materialization.

References:
- `secrets/external-secrets/`
- `secrets/guides/secret-lifecycle.md`

## Rotation and Lifecycle

Minimum lifecycle steps:
1. Provision secret with ownership metadata.
2. Distribute via approved sync/injection path.
3. Rotate on schedule based on risk and dependency.
4. Validate consumer reload behavior.
5. Retire and revoke during service offboarding.

Operational guides:
- `secrets/guides/secret-lifecycle.md`
- `secrets/guides/emergency-rotation.md`
- `secrets/guides/secret-offboarding.md`

## Anti-Patterns

Do not:
- Commit `.env` files containing real secrets.
- Store secrets directly in container images.
- Reuse identical credentials across environments.
- Keep long-lived cloud keys in CI by default.

## Implementation Pointers

- Secret infrastructure and patterns: `secrets/`
- Terraform-driven rotation (optional): `ci-security/secret-rotation/`
- Runtime security and compliance context: `secops/`, `policy/`
