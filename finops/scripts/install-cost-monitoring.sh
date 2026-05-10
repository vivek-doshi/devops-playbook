#!/usr/bin/env bash
# finops/scripts/install-cost-monitoring.sh
# Install Kubecost or OpenCost using Helm.
#
# Usage:
#   ./install-cost-monitoring.sh --tool kubecost
#   ./install-cost-monitoring.sh --tool opencost
#   ./install-cost-monitoring.sh --tool kubecost --cloud-provider aws --cluster-name prod

set -euo pipefail

TOOL="kubecost"
NAMESPACE="finops"
CLOUD_PROVIDER="aws"
CLUSTER_NAME="production"
DRY_RUN=false
HELM_VALUES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../helm" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)           TOOL="$2"; shift 2 ;;
    --namespace)      NAMESPACE="$2"; shift 2 ;;
    --cloud-provider) CLOUD_PROVIDER="$2"; shift 2 ;;
    --cluster-name)   CLUSTER_NAME="$2"; shift 2 ;;
    --dry-run)        DRY_RUN=true; shift ;;
    --help)
      echo "Usage: $0 --tool kubecost|opencost [--cloud-provider aws|azure|gcp] [--cluster-name NAME]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

HELM_FLAGS=()
[[ "$DRY_RUN" == "true" ]] && HELM_FLAGS+=("--dry-run")

echo "==> Installing $TOOL in namespace $NAMESPACE (cloud: $CLOUD_PROVIDER, cluster: $CLUSTER_NAME)"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NAMESPACE" \
  finops.org/costcenter=platform-infra \
  finops.org/environment=production \
  --overwrite

case "$TOOL" in
  kubecost)
    echo "==> Adding Kubecost Helm repo ..."
    helm repo add kubecost https://kubecost.github.io/cost-analyzer/ --force-update
    helm repo update

    echo "==> Installing Kubecost ..."
    helm upgrade --install kubecost kubecost/cost-analyzer \
      --namespace "$NAMESPACE" \
      --values "$HELM_VALUES_DIR/kubecost-values.yaml" \
      --set kubecostToken="" \
      --set global.prometheus.fqdn="http://prometheus-operated.monitoring.svc.cluster.local:9090" \
      --set global.grafana.enabled=false \
      --set global.grafana.proxy=false \
      --set networkCosts.enabled=true \
      --wait \
      "${HELM_FLAGS[@]}"

    echo "==> Kubecost installed. Access UI:"
    echo "    kubectl port-forward svc/kubecost-cost-analyzer -n $NAMESPACE 9090:9090"
    echo "    Open: http://localhost:9090"
    ;;

  opencost)
    echo "==> Adding OpenCost Helm repo ..."
    helm repo add opencost https://opencost.github.io/opencost-helm-chart --force-update
    helm repo update

    echo "==> Installing OpenCost ..."
    helm upgrade --install opencost opencost/opencost \
      --namespace "$NAMESPACE" \
      --set opencost.prometheus.internal.enabled=false \
      --set opencost.prometheus.external.url="http://prometheus-operated.monitoring.svc.cluster.local:9090" \
      --set opencost.cloudProviderApiKey="" \
      --wait \
      "${HELM_FLAGS[@]}"

    echo "==> OpenCost installed. Access UI:"
    echo "    kubectl port-forward svc/opencost -n $NAMESPACE 9090:9090"
    echo "    Open: http://localhost:9090"
    ;;

  *)
    echo "ERROR: Unknown tool '$TOOL'. Choose 'kubecost' or 'opencost'."
    exit 1
    ;;
esac

echo ""
echo "==> Verifying deployment ..."
sleep 10
kubectl get pods -n "$NAMESPACE" 2>/dev/null | head -10 || true

echo ""
echo "==> $TOOL installed successfully!"
echo "    Next: Configure cloud provider credentials in docs/cloud-provider-setup.md"
