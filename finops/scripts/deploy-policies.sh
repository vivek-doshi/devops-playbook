#!/usr/bin/env bash
# finops/scripts/deploy-policies.sh
# Deploy all FinOps Kyverno ClusterPolicy resources.
# Usage:
#   ./deploy-policies.sh [--audit-mode] [--dry-run] [--validate-only]
#
# Options:
#   --audit-mode     Override all policies to Audit mode (non-blocking)
#   --dry-run        Preview what would be applied without making changes
#   --validate-only  Validate policy syntax without deploying
#   --namespace NS   Restrict policy scope to a specific namespace (for testing)

set -euo pipefail

POLICIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../policies" && pwd)"
AUDIT_MODE=false
DRY_RUN=false
VALIDATE_ONLY=false
KUBECTL_FLAGS=()
FAILURES=0
SUCCESSES=0

# ─── argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --audit-mode)     AUDIT_MODE=true; shift ;;
    --dry-run)        DRY_RUN=true; KUBECTL_FLAGS+=("--dry-run=client"); shift ;;
    --validate-only)  VALIDATE_ONLY=true; shift ;;
    --namespace)      shift ;; # namespace arg (informational only for ClusterPolicies)
    --help)
      echo "Usage: $0 [--audit-mode] [--dry-run] [--validate-only]"
      echo ""
      echo "Options:"
      echo "  --audit-mode     Set all policies to Audit mode (non-blocking) for testing"
      echo "  --dry-run        Preview changes without applying"
      echo "  --validate-only  Check policy YAML syntax only"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── preflight checks ─────────────────────────────────────────────────────────
echo "==> Checking prerequisites ..."

if ! command -v kubectl &>/dev/null; then
  echo "ERROR: kubectl is not installed or not in PATH."
  exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
  echo "ERROR: Cannot connect to Kubernetes cluster. Check your kubeconfig."
  exit 1
fi

# Check Kyverno is installed
if ! kubectl get crd clusterpolicies.kyverno.io &>/dev/null; then
  echo "ERROR: Kyverno CRD 'clusterpolicies.kyverno.io' not found."
  echo "Install Kyverno first: https://kyverno.io/docs/installation/"
  exit 1
fi

# Check Kyverno CLI if validate-only
if [[ "$VALIDATE_ONLY" == "true" ]] && ! command -v kyverno &>/dev/null; then
  echo "WARNING: kyverno CLI not found. Falling back to kubectl dry-run for validation."
  VALIDATE_ONLY=false
  DRY_RUN=true
fi

echo "    kubectl: $(kubectl version --client --short 2>/dev/null | head -1)"
echo "    Kyverno CRD: present"

# ─── discover policy files ────────────────────────────────────────────────────
POLICY_FILES=$(find "$POLICIES_DIR" -name "*.yaml" ! -name "test-*" | sort)

if [[ -z "$POLICY_FILES" ]]; then
  echo "No policy YAML files found in $POLICIES_DIR."
  exit 0
fi

echo ""
echo "==> Found policy files:"
for f in $POLICY_FILES; do
  echo "    $(basename "$f")"
done

# ─── validate-only mode ───────────────────────────────────────────────────────
if [[ "$VALIDATE_ONLY" == "true" ]]; then
  echo ""
  echo "==> Validating policy syntax using kyverno CLI ..."
  for policy_file in $POLICY_FILES; do
    filename=$(basename "$policy_file")
    echo "  -> Validating: $filename"
    if kyverno validate "$policy_file" 2>&1; then
      echo "     OK"
      SUCCESSES=$((SUCCESSES + 1))
    else
      echo "     FAIL"
      FAILURES=$((FAILURES + 1))
    fi
  done
  echo ""
  echo "Validation complete: $SUCCESSES passed, $FAILURES failed"
  exit $([[ $FAILURES -eq 0 ]] && echo 0 || echo 1)
fi

# ─── apply policies ───────────────────────────────────────────────────────────
echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "==> DRY-RUN mode: no changes will be applied."
fi
if [[ "$AUDIT_MODE" == "true" ]]; then
  echo "==> AUDIT mode: overriding all policies to Audit (non-blocking)."
fi
echo ""

for policy_file in $POLICY_FILES; do
  filename=$(basename "$policy_file")
  echo "  -> Applying: $filename"

  # In audit mode, patch validationFailureAction to Audit before applying
  if [[ "$AUDIT_MODE" == "true" ]]; then
    TMP_FILE=$(mktemp /tmp/finops-policy-XXXXXX.yaml)
    sed 's/validationFailureAction: Enforce/validationFailureAction: Audit/g' \
        "$policy_file" > "$TMP_FILE"
    APPLY_FILE="$TMP_FILE"
  else
    APPLY_FILE="$policy_file"
  fi

  if kubectl apply "${KUBECTL_FLAGS[@]}" -f "$APPLY_FILE" 2>&1; then
    echo "     OK"
    SUCCESSES=$((SUCCESSES + 1))
  else
    echo "     FAIL"
    FAILURES=$((FAILURES + 1))
  fi

  [[ "$AUDIT_MODE" == "true" ]] && rm -f "$TMP_FILE" || true
done

# ─── verify deployment ────────────────────────────────────────────────────────
if [[ "$DRY_RUN" != "true" && $FAILURES -eq 0 ]]; then
  echo ""
  echo "==> Verifying deployed policies ..."
  kubectl get clusterpolicies -l finops.org/policy-id 2>/dev/null \
    | head -20 || true
fi

# ─── summary ──────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Policy Deployment Summary"
echo "========================================"
echo "  Mode      : $([[ "$AUDIT_MODE" == "true" ]] && echo "Audit" || echo "Enforce")"
echo "  Dry-run   : $DRY_RUN"
echo "  Succeeded : $SUCCESSES"
echo "  Failed    : $FAILURES"
echo "========================================"

if [[ $FAILURES -gt 0 ]]; then
  echo "Some policies failed. Review errors above."
  exit 1
fi
echo "All FinOps policies deployed successfully!"
