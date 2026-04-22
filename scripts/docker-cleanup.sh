#!/usr/bin/env bash
# ============================================================
# SCRIPT: docker-cleanup.sh — Docker Resource Cleanup
# WHEN TO USE: Reclaiming disk space on CI runners or dev machines
# PREREQUISITES: Docker CLI installed
# USAGE: ./scripts/docker-cleanup.sh [--dry-run]
# MATURITY: Stable
# ============================================================
# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
set -euo pipefail

# Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
DRY_RUN=${1:-}

# Note 3: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  echo "=== DRY RUN — nothing will be deleted ==="
  # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  docker system df
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  exit 0
# Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
fi

# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
echo "Removing stopped containers..."
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
docker container prune -f

echo "Removing unused images..."
docker image prune -f

echo "Removing unused volumes..."
docker volume prune -f

echo "Removing unused networks..."
docker network prune -f

echo "=== Space freed ==="
docker system df
