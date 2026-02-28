#!/usr/bin/env bash
# ============================================================
# SCRIPT: k8s-rollout-check.sh — Kubernetes Rollout Monitor
# WHEN TO USE: Post-deploy verification in CD pipelines
# PREREQUISITES: kubectl configured with cluster access
# USAGE: ./scripts/k8s-rollout-check.sh <namespace> <deployment-name> [timeout-seconds]
# MATURITY: Stable
# ============================================================
set -euo pipefail

NAMESPACE=${1:?Usage: $0 <namespace> <deployment-name> [timeout]}
DEPLOYMENT=${2:?Deployment name required}
TIMEOUT=${3:-120}

echo "Waiting for rollout: $DEPLOYMENT in namespace $NAMESPACE (timeout: ${TIMEOUT}s)"

kubectl rollout status deployment/"$DEPLOYMENT" \
  --namespace "$NAMESPACE" \
  --timeout "${TIMEOUT}s"

echo "✅ Rollout complete: $DEPLOYMENT"

# Show running pods
kubectl get pods -n "$NAMESPACE" -l "app=$DEPLOYMENT"
