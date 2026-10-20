#!/usr/bin/env bash
set -euo pipefail

: "${ARGOCD_SERVER:?Set ARGOCD_SERVER to the Argo CD API endpoint}"
: "${ARGOCD_APP_NAME:?Set ARGOCD_APP_NAME to the Argo CD Application name}"
: "${ARGOCD_AUTH_TOKEN:?Set ARGOCD_AUTH_TOKEN to an Argo CD token with read-only application access}"

# Production deployment is a protected Git promotion. Argo CD's automated sync
# performs the reconciliation; CI only waits for the controller's result.
docker run --rm \
  -e ARGOCD_AUTH_TOKEN \
  quay.io/argoproj/argocd:v2.12.3 \
  app wait "$ARGOCD_APP_NAME" \
  --server "$ARGOCD_SERVER" \
  --grpc-web \
  --sync \
  --health \
  --timeout 300
