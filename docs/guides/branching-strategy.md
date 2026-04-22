<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Branching Strategy Guide

Overview of common branching strategies with trade-off analysis.

<!-- Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
---

## Strategies Compared

<!-- Note 3: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 1. Trunk-Based Development (Recommended for CI/CD)

```
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
main ──────────────────────────────────────────►
      ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑
      <!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      short-lived feature branches (1-3 days)
```

<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Developers create short-lived branches, merge frequently to `main`
- `main` is always deployable
<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Feature flags control rollout of incomplete features
- **Best for**: teams with good test coverage and CI discipline

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
### 2. GitFlow

```
<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
main ──────────────────────────────────────────►
  ↑                                             ↑
  <!-- Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
  └──── develop ────────────────────────────────┘
            ↑           ↑              ↑
        <!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
        feature/*   release/*       hotfix/*
```

<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- Separate `develop` integration branch
- Structured release branches
<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Best for**: scheduled release cadence, multiple versions in production

### 3. GitHub Flow

<!-- Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
main ──────────────────────────────────────────►
      <!-- Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
      ↑       ↑       ↑       ↑
      feature branches merged via PR
<!-- Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```

- Simpler than GitFlow; every merge to `main` is a release
<!-- Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
- **Best for**: web apps with continuous deployment

---

<!-- Note 18: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
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
