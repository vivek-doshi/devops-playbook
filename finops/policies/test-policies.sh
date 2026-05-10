#!/usr/bin/env bash
# finops/policies/test-policies.sh
# Validates all Kyverno ClusterPolicy files using the Kyverno CLI test framework.
# Tests both valid and invalid Pod manifests to verify enforcement and error messages.
#
# Prerequisites:
#   kyverno CLI installed: https://kyverno.io/docs/kyverno-cli/#installation
#
# Usage:
#   ./finops/policies/test-policies.sh
#   ./finops/policies/test-policies.sh --policy require-cost-labels.yaml
#   ./finops/policies/test-policies.sh --help

set -euo pipefail

POLICIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$(mktemp -d)"
FAILURES=0
POLICY_FILTER=""

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --policy) POLICY_FILTER="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--policy <filename>]"
      echo "  Runs kyverno validate + kyverno test on all FinOps ClusterPolicies."
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── Check kyverno CLI ────────────────────────────────────────────────────────
if ! command -v kyverno &>/dev/null; then
  echo "ERROR: kyverno CLI not found."
  echo "Install: https://kyverno.io/docs/kyverno-cli/#installation"
  exit 1
fi
echo "==> kyverno CLI: $(kyverno version 2>/dev/null | head -1)"

# ─── Validate YAML syntax ─────────────────────────────────────────────────────
echo ""
echo "==> Validating policy YAML syntax ..."
for policy in "$POLICIES_DIR"/*.yaml; do
  [[ -z "$POLICY_FILTER" || "$(basename "$policy")" == "$POLICY_FILTER" ]] || continue
  [[ "$(basename "$policy")" == "README.md" ]] && continue
  echo -n "  Validating $(basename "$policy") ... "
  if kyverno validate "$policy" &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    kyverno validate "$policy" || true
    FAILURES=$((FAILURES + 1))
  fi
done

# ─── Create test fixture Pod manifests ───────────────────────────────────────
echo ""
echo "==> Creating test fixtures ..."

# Valid pod — all required labels present, resource limits set
cat > "$TEMP_DIR/pod-valid.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: valid-pod
  namespace: test-ns
  labels:
    app: myapp
    finops.org/costcenter: "engineering"
    finops.org/environment: "production"
  annotations:
    finops.org/gpu-approved: "true"
spec:
  containers:
    - name: app
      image: nginx:1.25
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
EOF

# Invalid pod — missing cost labels
cat > "$TEMP_DIR/pod-no-labels.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: no-label-pod
  namespace: test-ns
  labels:
    app: myapp
spec:
  containers:
    - name: app
      image: nginx:1.25
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
EOF

# Invalid pod — missing resource limits
cat > "$TEMP_DIR/pod-no-limits.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: no-limits-pod
  namespace: test-ns
  labels:
    finops.org/costcenter: "engineering"
    finops.org/environment: "production"
spec:
  containers:
    - name: app
      image: nginx:1.25
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
EOF

# Invalid pod — GPU without approval
cat > "$TEMP_DIR/pod-gpu-unapproved.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
  namespace: test-ns
  labels:
    finops.org/costcenter: "engineering"
    finops.org/environment: "production"
spec:
  containers:
    - name: trainer
      image: nvidia/cuda:12.0-runtime
      resources:
        requests:
          nvidia.com/gpu: "1"
        limits:
          cpu: "4"
          memory: "8Gi"
          nvidia.com/gpu: "1"
EOF

# Valid GPU pod — with approval annotation
cat > "$TEMP_DIR/pod-gpu-approved.yaml" <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod-approved
  namespace: test-ns
  labels:
    finops.org/costcenter: "data-science"
    finops.org/environment: "production"
  annotations:
    finops.org/gpu-approved: "true"
    finops.org/gpu-cost-center: "data-science"
    finops.org/gpu-justification: "ML model training"
spec:
  containers:
    - name: trainer
      image: nvidia/cuda:12.0-runtime
      resources:
        requests:
          nvidia.com/gpu: "1"
        limits:
          cpu: "4"
          memory: "8Gi"
          nvidia.com/gpu: "1"
EOF

echo "  Fixtures created in $TEMP_DIR"

# ─── Run kyverno apply tests ──────────────────────────────────────────────────
echo ""
echo "==> Testing require-cost-labels policy ..."

run_test() {
  local policy="$1"
  local resource="$2"
  local expect_pass="$3"   # "pass" or "fail"
  local description="$4"

  [[ -z "$POLICY_FILTER" || "$(basename "$policy")" == "$POLICY_FILTER" ]] || return 0
  [[ -f "$POLICIES_DIR/$(basename "$policy")" ]] || return 0

  echo -n "  [$description] "
  OUTPUT=$(kyverno apply "$POLICIES_DIR/$(basename "$policy")" --resource="$resource" 2>&1 || true)

  if [[ "$expect_pass" == "pass" ]]; then
    if echo "$OUTPUT" | grep -q "pass: 1"; then
      echo "PASS ✓"
    else
      echo "FAIL ✗ (expected pass)"
      echo "    Output: $(echo "$OUTPUT" | tail -5)"
      FAILURES=$((FAILURES + 1))
    fi
  else
    if echo "$OUTPUT" | grep -q "fail: 1\|violations found"; then
      echo "PASS ✓ (correctly rejected)"
    else
      echo "FAIL ✗ (expected rejection)"
      echo "    Output: $(echo "$OUTPUT" | tail -5)"
      FAILURES=$((FAILURES + 1))
    fi
  fi
}

# require-cost-labels tests
run_test "require-cost-labels.yaml" "$TEMP_DIR/pod-valid.yaml"         "pass" "Valid pod with all labels → allowed"
run_test "require-cost-labels.yaml" "$TEMP_DIR/pod-no-labels.yaml"     "fail" "Pod without labels → blocked"

# enforce-resource-limits tests
echo ""
echo "==> Testing enforce-resource-limits policy ..."
run_test "enforce-resource-limits.yaml" "$TEMP_DIR/pod-valid.yaml"     "pass" "Pod with limits → allowed"
run_test "enforce-resource-limits.yaml" "$TEMP_DIR/pod-no-limits.yaml" "fail" "Pod without limits → blocked"

# gpu-approval-gate tests
echo ""
echo "==> Testing gpu-approval-gate policy ..."
run_test "gpu-approval-gate.yaml" "$TEMP_DIR/pod-gpu-approved.yaml"    "pass" "GPU pod with approval → allowed"
run_test "gpu-approval-gate.yaml" "$TEMP_DIR/pod-gpu-unapproved.yaml"  "fail" "GPU pod without approval → blocked"

# ─── Results ──────────────────────────────────────────────────────────────────
echo ""
echo "=========================="
if [[ $FAILURES -eq 0 ]]; then
  echo "  All policy tests PASSED ✅"
else
  echo "  $FAILURES test(s) FAILED ❌"
  exit 1
fi
