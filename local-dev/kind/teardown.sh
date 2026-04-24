#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="devops-playbook"
REGISTRY_NAME="kind-registry"

# Delete the Kind cluster only when it exists so repeated teardown runs remain safe.
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
fi

# Remove the local registry container only when it exists so repeated teardown runs stay idempotent.
if docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  docker rm -f "$REGISTRY_NAME" >/dev/null
fi

printf 'Local Kind environment removed.\n'
