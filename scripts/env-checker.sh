#!/usr/bin/env bash
# ============================================================
# SCRIPT: env-checker.sh — Environment Variable Validator
# WHEN TO USE: Start of CI/CD jobs to fail fast on missing config
# PREREQUISITES: None
# USAGE: ./scripts/env-checker.sh VAR1 VAR2 VAR3
# MATURITY: Stable
# ============================================================
set -euo pipefail

REQUIRED_VARS=("$@")

if [[ ${#REQUIRED_VARS[@]} -eq 0 ]]; then
  echo "Usage: $0 VAR1 VAR2 ..."
  exit 1
fi

MISSING=()
for VAR in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!VAR:-}" ]]; then
    MISSING+=("$VAR")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required environment variables:"
  for VAR in "${MISSING[@]}"; do
    echo "   - $VAR"
  done
  exit 1
fi

echo "✅ All required environment variables are set."
