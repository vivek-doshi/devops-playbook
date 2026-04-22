#!/usr/bin/env bash
# ============================================================
# SCRIPT: k8s-rollout-check.sh — Kubernetes Rollout Monitor
# WHEN TO USE: Post-deploy verification in CD pipelines
# PREREQUISITES: kubectl configured with cluster access
# USAGE: ./scripts/k8s-rollout-check.sh <namespace> <deployment-name> [timeout-seconds]
# MATURITY: Stable
# ============================================================
# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
set -euo pipefail

# Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
NAMESPACE=${1:?Usage: $0 <namespace> <deployment-name> [timeout]}
# Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
DEPLOYMENT=${2:?Deployment name required}
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
TIMEOUT=${3:-120}

# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
echo "Waiting for rollout: $DEPLOYMENT in namespace $NAMESPACE (timeout: ${TIMEOUT}s)"

# Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
kubectl rollout status deployment/"$DEPLOYMENT" \
  --namespace "$NAMESPACE" \
  --timeout "${TIMEOUT}s"

echo "✅ Rollout complete: $DEPLOYMENT"

# Show running pods
kubectl get pods -n "$NAMESPACE" -l "app=$DEPLOYMENT"
