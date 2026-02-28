# Versioning Strategy Guide

---

## Semantic Versioning (SemVer) — Recommended for Libraries and APIs

Format: `MAJOR.MINOR.PATCH` (e.g., `2.1.4`)

| Part | Increment when |
|------|----------------|
| MAJOR | Breaking API / behavior change |
| MINOR | New feature, backward compatible |
| PATCH | Bug fix, backward compatible |

Pre-release: `2.1.4-beta.1`, `2.1.4-rc.1`
Build metadata: `2.1.4+20260228`

### Automated SemVer

Use [Release Please](../ci/github-actions/_strategies/release-please.yml) with Conventional Commits to automate version bumps.

---

## Calendar Versioning (CalVer) — For Applications

Format: `YYYY.MM.DD` or `YYYY.MM.PATCH` (e.g., `2026.02.1`)

Good for: products with regular release cadence, where "what year is this from" is meaningful to users.

---

## Build Numbers — For Internal Artifacts

Use the CI build number as part of the image tag:

```
my-app:1.2.3-build.456
my-app:sha-a1b2c3d  # Git SHA (recommended for traceability)
```

**Never use `latest` in production** — it is not immutable and breaks rollback.

---

## Image Tagging Strategy

```bash
# Tag with Git SHA (always unique, traceable)
docker build -t my-app:sha-$(git rev-parse --short HEAD) .

# Also tag with semver on release
docker tag my-app:sha-abc1234 my-app:1.2.3
docker tag my-app:sha-abc1234 my-app:1.2
```
