# Quality Baselines

This folder defines language-specific quality defaults used by CI pipelines.

## Purpose

Use `quality/` to keep linting, test, and static-analysis behavior consistent across repositories.

## What's Inside

- `dotnet/`: .NET quality settings and templates.
- `javascript/`: JavaScript/TypeScript quality settings.
- `python/`: Python quality settings.
- `sonar-project.properties`: Shared SonarQube baseline.

## Use This Component Alone

- Apply one language baseline in a single service repository.
- Standardize local lint/test commands before pipeline integration.

## Use This Component With Others

- With `ci/`: Enforce quality gates in pull requests.
- With `ci-security/`: Combine code quality and security checks in one pipeline stage.
- With `docs/guides/pre-commit-setup.md`: Shift quality checks left to developer machines.

## Typical Adoption Flow

1. Copy relevant language config.
2. Run local lint and tests.
3. Wire checks into CI templates.
4. Set failure thresholds and quality gates.
