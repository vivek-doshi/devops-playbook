#!/usr/bin/env bash
# ============================================================
# SCRIPT: docker-cleanup.sh — Docker Resource Cleanup
# WHEN TO USE: Reclaiming disk space on CI runners or dev machines
# PREREQUISITES: Docker CLI installed
# USAGE: ./scripts/docker-cleanup.sh [--dry-run]
# MATURITY: Stable
# ============================================================
set -euo pipefail

DRY_RUN=${1:-}

if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo "=== DRY RUN — nothing will be deleted ==="
  docker system df
  exit 0
fi

echo "Removing stopped containers..."
docker container prune -f

echo "Removing unused images..."
docker image prune -f

echo "Removing unused volumes..."
docker volume prune -f

echo "Removing unused networks..."
docker network prune -f

echo "=== Space freed ==="
docker system df
