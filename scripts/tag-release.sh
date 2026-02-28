#!/usr/bin/env bash
# ============================================================
# SCRIPT: tag-release.sh — SemVer Git Tag Creator
# WHEN TO USE: Creating release tags (manual or from CI)
# PREREQUISITES: Git repository with existing tags (or starts at v0.0.0)
# USAGE: ./scripts/tag-release.sh [MAJOR|MINOR|PATCH] [optional-message]
# MATURITY: Stable
# ============================================================
set -euo pipefail

BUMP=${1:-PATCH}
MESSAGE=${2:-"Release"}

# Get latest tag
LATEST=$(git tag --sort=-version:refname | head -n1)
if [[ -z "$LATEST" ]]; then
  LATEST="v0.0.0"
fi

# Strip the 'v' prefix
VERSION=${LATEST#v}
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

case "$BUMP" in
  MAJOR) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  MINOR) MINOR=$((MINOR + 1)); PATCH=0 ;;
  PATCH) PATCH=$((PATCH + 1)) ;;
  *)     echo "Usage: $0 [MAJOR|MINOR|PATCH]"; exit 1 ;;
esac

NEW_TAG="v${MAJOR}.${MINOR}.${PATCH}"
echo "Tagging: $LATEST → $NEW_TAG"

git tag -a "$NEW_TAG" -m "$MESSAGE $NEW_TAG"
git push origin "$NEW_TAG"

echo "✅ Tagged and pushed $NEW_TAG"
