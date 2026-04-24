---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'runCommands', 'search']
description: 'Generate Kind and Minikube local Kubernetes setup scripts that allow developers to test Helm charts and Kustomize manifests before pushing to GitOps.'
---

# Local Kubernetes Environment Generator

You are a senior platform engineer. Generate local Kubernetes setup tooling using Kind so developers can test the Helm charts and Kustomize manifests in this repo before committing.

## Context

Read these files first:
- `cd/kubernetes/_base/` — understand the base manifests
- `cd/kubernetes/_overlays/dev/` — understand dev overlay configuration
- `cd/helm/webapp/` — understand the Helm chart structure
- `compose/README.md` — understand existing local dev patterns
- `GETTING_STARTED.md` — understand where to add the new scenario

## Your deliverables

### 1. `local-dev/kind/kind-config.yaml`

A Kind cluster configuration that:
- Creates a 1 control-plane + 2 worker node cluster
- Maps host ports 80 and 443 to the control-plane node (for ingress testing)
- Mounts a local directory (`./local-dev/kind/registry`) as a local image registry volume
- Uses `kindest/node:v1.29.0` — add a comment to update this alongside `kubernetes_version` in Terraform variables
- Sets resource limits appropriate for a developer laptop (2 CPU, 4Gi memory per node)
- Enables feature gates needed for the HPA resources in `cd/kubernetes/_base/hpa.yaml`

### 2. `local-dev/kind/setup.sh`

A bash script that:
- Checks prerequisites: `kind`, `kubectl`, `helm`, `docker` — exits with a clear error message if any are missing
- Creates the Kind cluster from `kind-config.yaml` if it does not already exist (idempotent)
- Sets up a local container registry at `localhost:5001` and connects it to the Kind network — add a comment explaining why this avoids DockerHub rate limits
- Installs the Nginx ingress controller via Helm, pinned to a specific chart version, and waits for it to be ready
- Applies the dev overlay: `kubectl apply -k cd/kubernetes/_overlays/dev/`
- Installs the webapp Helm chart: `helm upgrade --install webapp cd/helm/webapp -f cd/helm/webapp/values.dev.yaml`
- Prints a summary of running pods and services
- Prints the URL to access the app via the ingress (http://localhost)
- Includes `set -euo pipefail` and meaningful error messages throughout

### 3. `local-dev/kind/teardown.sh`

A bash script that:
- Deletes the Kind cluster
- Removes the local registry container
- Prints a confirmation message
- Is safe to run multiple times (idempotent)

### 4. `local-dev/kind/load-image.sh`

A helper script that:
- Accepts an image name as an argument
- Builds the image using `docker build` if a Dockerfile path is provided as a second argument
- Loads the image into the Kind cluster using `kind load docker-image`
- Tags the image for the local registry and pushes it
- Prints instructions for updating the Kustomize overlay to use the local image

### 5. `local-dev/README.md`

A guide covering:
- Prerequisites and installation links for Kind, kubectl, helm
- Quick start: three commands to get a running local cluster
- How to test a Helm chart change locally before pushing
- How to test a Kustomize overlay change
- How to tail logs from a local pod (reference `stern` from the devcontainer)
- How to access the local app via browser
- Common issues: Docker Desktop resource limits, port conflicts on 80/443, image pull failures
- A comparison table: Kind vs Minikube vs Docker Desktop Kubernetes — when to use each

### 6. Update `GETTING_STARTED.md`

Add a new scenario row:
- "I need to test my K8s manifests locally before committing" → `local-dev/kind/setup.sh`

## Style rules

- Shell scripts must be POSIX-compatible and tested on macOS and Linux (WSL2)
- Every command in the setup script must have a comment explaining what it does and why
- Use meaningful exit codes and error messages — never `exit 1` with no message
- The setup must be idempotent — running it twice must not create duplicate resources or fail
- Add `# <-- CHANGE THIS` comments on the Kind node image version and ingress chart version