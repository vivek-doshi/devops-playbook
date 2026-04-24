#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="devops-playbook"
KIND_CONFIG="local-dev/kind/kind-config.yaml"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"
REGISTRY_DATA_DIR="local-dev/kind/registry"
INGRESS_RELEASE="ingress-nginx"
INGRESS_NAMESPACE="ingress-nginx"
INGRESS_CHART_VERSION="4.15.1" # <-- CHANGE THIS: bump this when you want a newer ingress-nginx chart
DEV_NAMESPACE="dev"
HELM_NAMESPACE="webapp"
SMOKE_SOURCE_IMAGE="docker.io/nginxinc/nginx-unprivileged:1.27.5-alpine"
SMOKE_TARGET_IMAGE="localhost:5001/webapp:dev-latest"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Required command '$1' is not installed or not on PATH."
  fi
}

# Confirm Kind is installed before any local cluster work begins.
require_command kind
# Confirm kubectl is available so the script can configure the cluster after creation.
require_command kubectl
# Confirm Helm is installed for ingress-nginx and chart-based smoke tests.
require_command helm
# Confirm Docker is available because Kind nodes and the local registry both run as containers.
require_command docker

# Create the host-backed registry directory before Kind tries to mount it into the node containers.
mkdir -p "$REGISTRY_DATA_DIR"

# Start the local registry once so repeated setup runs reuse the same cached images instead of pulling from Docker Hub each time.
if ! docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
  docker run -d --restart=always -p "${REGISTRY_PORT}:5000" --name "$REGISTRY_NAME" -v "$(pwd)/${REGISTRY_DATA_DIR}:/var/lib/registry" registry:2 >/dev/null
fi

# Create the Kind cluster only when it does not already exist so the script remains idempotent.
if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config "$KIND_CONFIG"
fi

# Connect the registry container to the Kind Docker network so containerd mirrors can reach it by name.
if [ "$(docker inspect -f '{{if .NetworkSettings.Networks.kind}}attached{{else}}detached{{end}}' "$REGISTRY_NAME")" = "detached" ]; then
  docker network connect kind "$REGISTRY_NAME"
fi

# Cap each Kind node container to laptop-friendly resources so one local cluster does not consume the whole workstation.
for node in $(kind get nodes --name "$CLUSTER_NAME"); do
  docker update --cpus 2 --memory 4g "$node" >/dev/null
done

# Label the control-plane node so the ingress controller can bind host ports 80 and 443 on the node that exposes them.
kubectl label node "${CLUSTER_NAME}-control-plane" ingress-ready=true --overwrite >/dev/null

# Publish the registry location inside the cluster so developers can discover the localhost mirror pattern from Kubernetes itself.
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# Register the ingress-nginx repository so Helm can install the same ingress pattern repeatedly on fresh clusters.
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
# Refresh Helm repository metadata so the pinned ingress chart version resolves predictably.
helm repo update >/dev/null

# Install or upgrade ingress-nginx with host ports on the labelled control-plane node so http://localhost works without extra tunnelling.
helm upgrade --install "$INGRESS_RELEASE" ingress-nginx/ingress-nginx \
  --namespace "$INGRESS_NAMESPACE" \
  --create-namespace \
  --version "$INGRESS_CHART_VERSION" \
  --set controller.kind=DaemonSet \
  --set controller.hostPort.enabled=true \
  --set controller.service.type=ClusterIP \
  --set controller.nodeSelector.ingress-ready=true \
  --set controller.tolerations[0].key=node-role.kubernetes.io/control-plane \
  --set controller.tolerations[0].operator=Exists \
  --set controller.tolerations[0].effect=NoSchedule

# Wait for the ingress controller to become ready before applying manifests that depend on ingress routing.
kubectl rollout status daemonset/ingress-nginx-controller -n "$INGRESS_NAMESPACE" --timeout=180s

# Pull a pinned smoke-test image so the repo can demonstrate working manifests even before a project-specific image exists.
docker pull "$SMOKE_SOURCE_IMAGE" >/dev/null
# Tag the smoke-test image into the local registry namespace that both Kind and the host can reach.
docker tag "$SMOKE_SOURCE_IMAGE" "$SMOKE_TARGET_IMAGE"
# Push the smoke-test image to the local registry so in-cluster pulls avoid external registry rate limits.
docker push "$SMOKE_TARGET_IMAGE" >/dev/null
# Load the same image directly into Kind as a fast-path so the first deployment does not depend on registry pull timing.
kind load docker-image "$SMOKE_TARGET_IMAGE" --name "$CLUSTER_NAME"

# Create the dev namespace up front because the Kustomize overlay targets it but does not declare the Namespace object.
kubectl get namespace "$DEV_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$DEV_NAMESPACE" >/dev/null

# Create a placeholder secret so the base Deployment's secret reference resolves during local smoke tests.
kubectl create secret generic app-secrets -n "$DEV_NAMESPACE" --from-literal=db-password=localdev --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# Apply the dev overlay exactly as it exists in the repo so local runs exercise the same Kustomize entry point used in GitOps.
kubectl apply -k cd/kubernetes/_overlays/dev/

# Patch the ConfigMap for local development so the container sees a development environment instead of the production default.
kubectl patch configmap app-config -n "$DEV_NAMESPACE" --type merge -p '{"data":{"environment":"development","log-level":"debug"}}' >/dev/null

# Replace the placeholder image reference from the base overlay with the local registry image that is guaranteed to exist in this setup.
kubectl set image deployment/app app="$SMOKE_TARGET_IMAGE" -n "$DEV_NAMESPACE" >/dev/null

# Patch the health probes to `/` so the smoke-test image reports healthy while developers focus on manifest wiring first.
kubectl patch deployment app -n "$DEV_NAMESPACE" --type merge -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","livenessProbe":{"httpGet":{"path":"/","port":8080},"initialDelaySeconds":15,"periodSeconds":20},"readinessProbe":{"httpGet":{"path":"/","port":8080},"initialDelaySeconds":5,"periodSeconds":10}}]}}}}' >/dev/null

# Remove the production cert-manager annotation and pin the local host/path so the Kustomize ingress is reachable on http://localhost/.
kubectl patch ingress app -n "$DEV_NAMESPACE" --type merge -p '{"metadata":{"annotations":{"cert-manager.io/cluster-issuer":null,"nginx.ingress.kubernetes.io/rewrite-target":"/"}},"spec":{"tls":null,"rules":[{"host":"localhost","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"app","port":{"number":80}}}}]}}]}}' >/dev/null

# Wait for the Kustomize deployment to become ready so the local overlay test is complete before the Helm chart install starts.
kubectl rollout status deployment/app -n "$DEV_NAMESPACE" --timeout=180s

# Create a separate namespace for the Helm release so it can coexist with the Kustomize example without label or service collisions.
kubectl get namespace "$HELM_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$HELM_NAMESPACE" >/dev/null

# Install or upgrade the Helm chart with the same smoke-test image and local ingress host so chart changes are testable immediately.
helm upgrade --install webapp cd/helm/webapp \
  --namespace "$HELM_NAMESPACE" \
  --create-namespace \
  -f cd/helm/webapp/values.dev.yaml \
  --set image.repository=localhost:5001/webapp \
  --set image.tag=dev-latest \
  --set probes.liveness.path=/ \
  --set probes.readiness.path=/

# Create a local-only Service and Ingress for the Helm release because the example chart currently focuses on the Deployment template only.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: webapp
  namespace: ${HELM_NAMESPACE}
spec:
  selector:
    app.kubernetes.io/name: webapp
    app.kubernetes.io/instance: webapp
  ports:
    - name: http
      port: 80
      targetPort: http
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp
  namespace: ${HELM_NAMESPACE}
spec:
  ingressClassName: nginx
  rules:
    - host: localhost
      http:
        paths:
          - path: /helm
            pathType: Prefix
            backend:
              service:
                name: webapp
                port:
                  number: 80
EOF

# Wait for the Helm deployment so the chart-based path is ready before the script prints summary output.
kubectl rollout status deployment/webapp -n "$HELM_NAMESPACE" --timeout=180s

# Show the running workloads so developers can verify the control plane, overlay workload, and chart workload in one glance.
kubectl get pods -n "$INGRESS_NAMESPACE"
kubectl get pods -n "$DEV_NAMESPACE"
kubectl get pods -n "$HELM_NAMESPACE"

# Show the exposed services and ingress resources so developers can confirm routing targets and namespaces quickly.
kubectl get svc -n "$INGRESS_NAMESPACE"
kubectl get svc -n "$DEV_NAMESPACE"
kubectl get svc -n "$HELM_NAMESPACE"
kubectl get ingress -n "$DEV_NAMESPACE"
kubectl get ingress -n "$HELM_NAMESPACE"

# Print the localhost entry points last so the operator can open the cluster immediately after the script completes.
printf '\nKustomize overlay: http://localhost/\n'
printf 'Helm chart:       http://localhost/helm\n'
