#!/usr/bin/env bash
# ============================================================
# SCRIPT: tag-release.sh — SemVer Git Tag Creator
# WHEN TO USE: Creating release tags (manual or from CI)
# PREREQUISITES: Git repository with existing tags (or starts at v0.0.0)
# USAGE: ./scripts/tag-release.sh [MAJOR|MINOR|PATCH] [optional-message]
# MATURITY: Stable
# ============================================================
# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
set -euo pipefail

BUMP=${1:-PATCH}
# Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
MESSAGE=${2:-"Release"}

# Get latest tag
LATEST=$(git tag --sort=-version:refname | head -n1)
# Note 3: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
if [[ -z "$LATEST" ]]; then
  LATEST="v0.0.0"
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
fi

# Strip the 'v' prefix
VERSION=${LATEST#v}
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

case "$BUMP" in
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  MAJOR) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  MINOR) MINOR=$((MINOR + 1)); PATCH=0 ;;
  # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  PATCH) PATCH=$((PATCH + 1)) ;;
  *)     echo "Usage: $0 [MAJOR|MINOR|PATCH]"; exit 1 ;;
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
echo "Tagging: $LATEST → $NEW_TAG"

git tag -a "$NEW_TAG" -m "$MESSAGE $NEW_TAG"
# Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
git push origin "$NEW_TAG"

echo "✅ Tagged and pushed $NEW_TAG"
