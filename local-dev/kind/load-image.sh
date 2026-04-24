#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="devops-playbook"
REGISTRY_HOST="localhost:5001"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s <image-name[:tag]> [path-to-Dockerfile]\n' "$0" >&2
  exit 64
fi

IMAGE_NAME="$1"
DOCKERFILE_PATH="${2:-}"

IMAGE_REPOSITORY="${IMAGE_NAME%:*}"
IMAGE_TAG="${IMAGE_NAME##*:}"

if [ "$IMAGE_REPOSITORY" = "$IMAGE_TAG" ]; then
  IMAGE_REPOSITORY="$IMAGE_NAME"
  IMAGE_TAG="latest"
fi

LOCAL_REPOSITORY_NAME="${IMAGE_REPOSITORY##*/}"
REGISTRY_IMAGE="${REGISTRY_HOST}/${LOCAL_REPOSITORY_NAME}:${IMAGE_TAG}"

if [ -n "$DOCKERFILE_PATH" ]; then
  BUILD_CONTEXT="$(dirname "$DOCKERFILE_PATH")"
  # Build the image from the supplied Dockerfile path so developers can test local changes before publishing anywhere.
  docker build -t "$IMAGE_NAME" -f "$DOCKERFILE_PATH" "$BUILD_CONTEXT"
fi

# Load the image into Kind directly so it is available to the cluster even before a pull from the local registry occurs.
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

# Tag the image for the localhost registry that the Kind nodes mirror internally.
docker tag "$IMAGE_NAME" "$REGISTRY_IMAGE"

# Push the registry-tagged image so future pod restarts can pull it without rebuilding.
docker push "$REGISTRY_IMAGE"

printf 'Loaded image into Kind and pushed %s\n' "$REGISTRY_IMAGE"
printf '\nUpdate the Kustomize overlay image block to:\n'
printf 'images:\n'
printf '  - name: my-registry/my-app\n'
printf '    newName: %s\n' "${REGISTRY_HOST}/${LOCAL_REPOSITORY_NAME}"
printf '    newTag: %s\n' "$IMAGE_TAG"
printf '\nUpdate the Helm install values to:\n'
printf '  --set image.repository=%s --set image.tag=%s\n' "${REGISTRY_HOST}/${LOCAL_REPOSITORY_NAME}" "$IMAGE_TAG"
