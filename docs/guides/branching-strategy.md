# Branching Strategy Guide

This guide defines practical branching rules for repository contributions and downstream adoption in product repos.

## Recommended Default

Use trunk-based development with short-lived feature branches.

Why this fits this repository:
- Most changes are template and docs updates that benefit from small, frequent merges.
- CI templates across providers in `ci/` should stay aligned with minimal divergence.
- Security and policy guardrails are easier to keep consistent with smaller PRs.

## Branch Model

```text
main  -------------------------------------------------------------->
        \  \   \   \   \   \  short-lived branches (1-3 days)
```

Rules:
1. Branch from `main`.
2. Keep branch lifetime short.
3. Merge via pull request only.
4. Rebase or update frequently to reduce drift.

## When to Use Release Branches

Use release branches only when your consuming product has a staged release cadence that requires stabilization windows.

For this reference repo, avoid long-lived `develop` branches to reduce template drift.

## Pull Request Standards

1. One logical change per PR.
2. Link impacted areas (for example `ci/`, `cd/`, `policy/`, `docs/`).
3. Include validation notes and rollback considerations for operational changes.
4. Require at least one reviewer and passing checks before merge.

## Branch Protection Baseline

Protect `main` with:
- Pull request required.
- Required status checks.
- Up-to-date branch before merge.
- No force push.
- No deletion.

## Commit Convention

Use Conventional Commits to preserve release and changelog automation.

Examples:
```text
feat(ci): add reusable workflow for container scanning
fix(cd): correct kustomize image tag patch in prod overlay
docs(runbooks): clarify escalation path for SLO critical burn
chore(policy): update kyverno policy metadata annotations
```

Related:
- `docs/guides/conventional-commits.md`
- `docs/guides/versioning-strategy.md`
- `catalog/scripts/generate-codeowners.py`
