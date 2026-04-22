<!-- Note 1: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
# Versioning Strategy Guide

---

<!-- Note 2: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Semantic Versioning (SemVer) — Recommended for Libraries and APIs

Format: `MAJOR.MINOR.PATCH` (e.g., `2.1.4`)

<!-- Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| Part | Increment when |
|------|----------------|
<!-- Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| MAJOR | Breaking API / behavior change |
| MINOR | New feature, backward compatible |
<!-- Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
| PATCH | Bug fix, backward compatible |

Pre-release: `2.1.4-beta.1`, `2.1.4-rc.1`
<!-- Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Build metadata: `2.1.4+20260228`

### Automated SemVer

<!-- Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Use [Release Please](../ci/github-actions/_strategies/release-please.yml) with Conventional Commits to automate version bumps.

---

<!-- Note 8: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Calendar Versioning (CalVer) — For Applications

Format: `YYYY.MM.DD` or `YYYY.MM.PATCH` (e.g., `2026.02.1`)

<!-- Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
Good for: products with regular release cadence, where "what year is this from" is meaningful to users.

---

<!-- Note 10: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Build Numbers — For Internal Artifacts

Use the CI build number as part of the image tag:

<!-- Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
```
my-app:1.2.3-build.456
<!-- Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
my-app:sha-a1b2c3d  # Git SHA (recommended for traceability)
```

<!-- Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact. -->
**Never use `latest` in production** — it is not immutable and breaks rollback.

---

<!-- Note 14: Existing comments can be treated as intent markers; aligning code with documented intent improves long-term reliability. -->
## Image Tagging Strategy

```bash
# Tag with Git SHA (always unique, traceable)
docker build -t my-app:sha-$(git rev-parse --short HEAD) .

# Also tag with semver on release
docker tag my-app:sha-abc1234 my-app:1.2.3
docker tag my-app:sha-abc1234 my-app:1.2
```
