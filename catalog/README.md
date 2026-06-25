# Service Catalog

The service catalog is a Git-native ownership and governance registry.

## Purpose

Use `catalog/` to record service ownership, on-call routing, operational metadata, and governance attributes in version control.

## What's Inside

- `services/`: One service definition per file.
- `teams/`: Team metadata and ownership references.
- `schema/`: Validation schema for catalog entries.
- `scripts/`: Validation, CODEOWNERS generation, and migration utilities.

## Use This Component Alone

- Register one service and assign clear ownership.
- Validate metadata correctness in pull requests.

## Use This Component With Others

- With `ci/`: Enforce catalog validation in CI gates.
- With `policy/`: Require catalog registration for deployed workloads.
- With `docs/golden-paths/service-catalog.md`: Follow the full governance workflow.
- With `secops/compliance/`: Provide evidence for ownership and accountability controls.

## Quick Start

```bash
python catalog/scripts/validate-catalog.py --strict
python catalog/scripts/generate-codeowners.py
```

If ownership changes, regenerate CODEOWNERS in the same pull request.
