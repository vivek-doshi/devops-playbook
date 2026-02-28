# Branching Strategy Guide

Overview of common branching strategies with trade-off analysis.

---

## Strategies Compared

### 1. Trunk-Based Development (Recommended for CI/CD)

```
main ──────────────────────────────────────────►
      ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑
      short-lived feature branches (1-3 days)
```

- Developers create short-lived branches, merge frequently to `main`
- `main` is always deployable
- Feature flags control rollout of incomplete features
- **Best for**: teams with good test coverage and CI discipline

### 2. GitFlow

```
main ──────────────────────────────────────────►
  ↑                                             ↑
  └──── develop ────────────────────────────────┘
            ↑           ↑              ↑
        feature/*   release/*       hotfix/*
```

- Separate `develop` integration branch
- Structured release branches
- **Best for**: scheduled release cadence, multiple versions in production

### 3. GitHub Flow

```
main ──────────────────────────────────────────►
      ↑       ↑       ↑       ↑
      feature branches merged via PR
```

- Simpler than GitFlow; every merge to `main` is a release
- **Best for**: web apps with continuous deployment

---

## Branch Protection Rules (Recommended)

For `main` / `master`:
- Require pull request (1+ reviewer)
- Require status checks to pass (CI)
- Require branches to be up to date
- No force push
- No deletion

---

## Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) to enable automated versioning:

```
feat: add user authentication
fix: resolve null pointer in order service
chore: update dependencies
docs: update API documentation
BREAKING CHANGE: rename endpoint /users to /api/users
```
