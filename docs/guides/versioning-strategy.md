# Versioning Strategy Guide

This guide defines versioning and tagging conventions for templates, artifacts, and releases.

## Recommended Model

Use Semantic Versioning for reusable deliverables.

Format:
- `MAJOR.MINOR.PATCH`

Increment rules:
- `MAJOR`: breaking behavior or interface changes.
- `MINOR`: backward-compatible feature additions.
- `PATCH`: backward-compatible fixes.

## Artifact Tagging

For container and deployment artifacts:
1. Always publish immutable SHA tags.
2. Add semantic tags only for release milestones.
3. Do not use mutable `latest` for production deployment references.

Example:

```bash
docker build -t my-app:sha-$(git rev-parse --short HEAD) .
docker tag my-app:sha-abc1234 my-app:1.4.0
docker tag my-app:sha-abc1234 my-app:1.4
```

## Repository Release Flow

Suggested release sequence:
1. Merge changes using Conventional Commits.
2. Generate release version and tag.
3. Promote the same artifact across environments.
4. Record release notes and rollback references.

Related script:
- `scripts/tag-release.sh`

## CalVer Guidance

Calendar versioning is acceptable for operational bundles where release date visibility is more useful than API compatibility signaling.

Example:
- `2026.05.2`

## CI/CD Integration

- Ensure pipeline metadata includes git SHA and build identifier.
- Use release automation patterns from `ci/github-actions/` where available.
- Keep release gates aligned with `docs/guides/branching-strategy.md`.

## Related

- `docs/guides/conventional-commits.md`
- `docs/guides/branching-strategy.md`
- `ci/github-actions/`
