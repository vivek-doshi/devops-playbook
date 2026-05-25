# Environment Strategy Guide

This guide defines how environments are modeled and promoted in this repository.

## Standard Environment Flow

```text
developer -> dev -> staging -> production
```

Purpose by stage:
- `dev`: rapid validation and integration checks.
- `staging`: production-like verification and release confidence.
- `production`: controlled rollout with strict access and audit requirements.

## Configuration Strategy

Do not bake environment values into images.

Use environment-specific overlays and values:
- Kustomize overlays in `cd/kubernetes/_overlays/`
- Helm values files in `cd/helm/`
- Cloud/runtime config stores via `secrets/` and external providers

## Promotion Model

Use artifact promotion, not rebuild-per-environment.

Recommended flow:
1. CI builds image and tags with immutable SHA.
2. Dev deployment updates to that SHA.
3. Promotion PR updates staging to the same SHA.
4. Production promotion PR updates to the same SHA after approval.

## Access and Change Controls

Production controls:
- Git-based change only for deployment config.
- Least-privilege RBAC for deployment identities.
- Break-glass process documented and audited.
- Environment separation by namespace/account/subscription/project.

## Secrets and Identity Alignment

- Use workload identity federation for CI deploy identities.
- Keep secret source of truth in secret managers.
- Sync runtime secrets through patterns in `secrets/`.

## Validation Checklist

Before promoting to production:
1. CI checks are green.
2. Security and policy scans pass.
3. Staging smoke tests pass.
4. Rollback path is documented.
5. Runbook links exist for critical alerts.

Related:
- `docs/guides/github-actions-oidc.md`
- `docs/guides/secrets-management.md`
- `docs/decisions/ADR-003-gitops-strategy.md`
