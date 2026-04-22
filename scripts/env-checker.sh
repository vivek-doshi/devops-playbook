#!/usr/bin/env bash
# ============================================================
# SCRIPT: env-checker.sh — Environment Variable Validator
# WHEN TO USE: Start of CI/CD jobs to fail fast on missing config
# PREREQUISITES: None
# USAGE: ./scripts/env-checker.sh VAR1 VAR2 VAR3
# MATURITY: Stable
# ============================================================
# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
set -euo pipefail

REQUIRED_VARS=("$@")

# Note 2: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
if [[ ${#REQUIRED_VARS[@]} -eq 0 ]]; then
  echo "Usage: $0 VAR1 VAR2 ..."
  # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  exit 1
fi

# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
MISSING=()
for VAR in "${REQUIRED_VARS[@]}"; do
  # Note 5: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  if [[ -z "${!VAR:-}" ]]; then
    MISSING+=("$VAR")
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  fi
done

# Note 7: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "❌ Missing required environment variables:"
  # Note 8: Control flow should stay readable; predictable branches reduce defects and simplify troubleshooting.
  for VAR in "${MISSING[@]}"; do
    echo "   - $VAR"
  # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  done
  exit 1
fi

echo "✅ All required environment variables are set."
