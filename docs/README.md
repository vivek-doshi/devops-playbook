# Documentation Hub

This folder is the navigation layer for the entire repository.

## Purpose

Use `docs/` to understand architecture intent, implementation standards, and operational procedures before editing templates.

## What's Inside

- `golden-paths/`: End-to-end implementation workflows.
- `guides/`: Focused guidance on branching, environments, OIDC, secrets, and onboarding.
- `runbooks/`: Operational response procedures.
- `decisions/`: Architecture decision records (ADRs).
- `diagrams/`: Architecture and workflow diagrams.
- `ARCHITECTURE_DECISION_GUIDE.md`: Framework for selecting patterns safely.

## Use This Component Alone

- Learn one domain quickly from a single guide.
- Run incidents from standard runbooks.

## Use This Component With Others

- Start every major change in `docs/golden-paths/`, then execute in `docker/`, `ci/`, `cd/`, and `terraform/`.
- Use ADRs to justify implementation decisions across platform and security domains.
- Link runbooks from alerting rules in `observability/` and `secops/`.

## Suggested Reading Order

1. `docs/golden-paths/platform-onboarding.md`
2. `docs/guides/onboarding.md`
3. `docs/guides/environment-strategy.md`
4. `docs/decisions/README.md`
5. `docs/runbooks/README.md`
