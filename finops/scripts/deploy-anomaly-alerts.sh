#!/usr/bin/env bash
# finops/scripts/deploy-anomaly-alerts.sh
# Apply the cost anomaly Prometheus alerting rules and Alertmanager config.
# Validates rule syntax before applying, then reloads Prometheus and Alertmanager.
#
# Usage:
#   ./finops/scripts/deploy-anomaly-alerts.sh
#   ./finops/scripts/deploy-anomaly-alerts.sh --dry-run
#   ./finops/scripts/deploy-anomaly-alerts.sh --namespace monitoring

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_DIR="$(cd "$SCRIPTS_DIR/../prometheus" && pwd)"
NAMESPACE="monitoring"
DRY_RUN=false
PROMETHEUS_URL="http://prometheus-operated.${NAMESPACE}.svc.cluster.local:9090"
ALERTMANAGER_URL="http://alertmanager-operated.${NAMESPACE}.svc.cluster.local:9093"
FAILURES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --namespace)  NAMESPACE="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--dry-run] [--namespace NAMESPACE]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

ANOMALY_RULES="$PROMETHEUS_DIR/anomaly-alerts.yaml"
ANOMALY_AM_CONFIG="$PROMETHEUS_DIR/alertmanager-anomaly-config.yaml"

echo "========================================"
echo "  FinOps Anomaly Alert Deployment"
echo "  Namespace: $NAMESPACE"
echo "  Dry-run  : $DRY_RUN"
echo "========================================"
echo ""

# ─── Step 1: Validate alert rule YAML ────────────────────────────────────────
echo "==> Step 1: Validating anomaly alerting rules ..."

if command -v promtool &>/dev/null; then
  echo -n "  promtool check rules $ANOMALY_RULES ... "
  if promtool check rules "$ANOMALY_RULES" &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    promtool check rules "$ANOMALY_RULES" || true
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "  WARNING: promtool not found — skipping rule syntax validation."
  echo "  Install: https://prometheus.io/docs/prometheus/latest/getting_started/"
fi

# ─── Step 2: Validate Alertmanager config syntax ──────────────────────────────
echo ""
echo "==> Step 2: Validating Alertmanager anomaly config ..."

if command -v amtool &>/dev/null; then
  echo -n "  amtool check-config $ANOMALY_AM_CONFIG ... "
  if amtool check-config "$ANOMALY_AM_CONFIG" &>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
    amtool check-config "$ANOMALY_AM_CONFIG" || true
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "  WARNING: amtool not found — skipping Alertmanager config validation."
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "ERROR: Validation failed with $FAILURES error(s). Aborting."
  exit 1
fi

# ─── Step 3: Check Kubernetes CRDs ───────────────────────────────────────────
echo ""
echo "==> Step 3: Verifying Kubernetes prerequisites ..."

if [[ "$DRY_RUN" == "false" ]]; then
  if ! kubectl get crd prometheusrules.monitoring.coreos.com &>/dev/null; then
    echo "ERROR: PrometheusRule CRD not found. Is kube-prometheus-stack installed?"
    exit 1
  fi
  echo "  PrometheusRule CRD: OK"
fi

# ─── Step 4: Apply anomaly PrometheusRule ─────────────────────────────────────
echo ""
echo "==> Step 4: Deploying anomaly alerting rules ..."

if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [dry-run] Would apply: $ANOMALY_RULES"
  kubectl apply -f "$ANOMALY_RULES" -n "$NAMESPACE" --dry-run=client
else
  kubectl apply -f "$ANOMALY_RULES" -n "$NAMESPACE"
  echo "  Applied: $(basename "$ANOMALY_RULES")"
fi

# ─── Step 5: Apply Alertmanager anomaly config ────────────────────────────────
echo ""
echo "==> Step 5: Deploying Alertmanager anomaly routing config ..."

if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [dry-run] Would apply: $ANOMALY_AM_CONFIG"
else
  # Check if it's a raw Alertmanager config or a PrometheusRule/AlertmanagerConfig CRD
  if grep -q "^kind: AlertmanagerConfig" "$ANOMALY_AM_CONFIG" 2>/dev/null; then
    kubectl apply -f "$ANOMALY_AM_CONFIG" -n "$NAMESPACE"
    echo "  Applied AlertmanagerConfig CRD."
  else
    # Create/update as a secret (standard Alertmanager pattern)
    kubectl create secret generic alertmanager-finops-anomaly \
      --from-file=alertmanager.yaml="$ANOMALY_AM_CONFIG" \
      -n "$NAMESPACE" \
      --dry-run=client -o yaml | kubectl apply -f -
    echo "  Updated alertmanager-finops-anomaly secret."
  fi
fi

# ─── Step 6: Reload Prometheus ────────────────────────────────────────────────
echo ""
echo "==> Step 6: Triggering Prometheus config reload ..."

if [[ "$DRY_RUN" == "false" ]]; then
  if curl -s -X POST "${PROMETHEUS_URL}/-/reload" &>/dev/null; then
    echo "  Prometheus reloaded successfully."
  else
    echo "  WARNING: Prometheus reload failed (may reload automatically via operator)."
  fi
fi

# ─── Step 7: Reload Alertmanager ──────────────────────────────────────────────
echo ""
echo "==> Step 7: Triggering Alertmanager config reload ..."

if [[ "$DRY_RUN" == "false" ]]; then
  if curl -s -X POST "${ALERTMANAGER_URL}/-/reload" &>/dev/null; then
    echo "  Alertmanager reloaded successfully."
  else
    echo "  WARNING: Alertmanager reload failed (may reload automatically via operator)."
  fi
fi

# ─── Step 8: Verify rules are loaded ─────────────────────────────────────────
echo ""
echo "==> Step 8: Verifying anomaly alert rules are loaded ..."

if [[ "$DRY_RUN" == "false" ]]; then
  sleep 5
  RULES=$(kubectl get prometheusrule -n "$NAMESPACE" -l "finops.org/component=anomaly-detection" 2>/dev/null | grep -c finops || echo "0")
  echo "  FinOps anomaly PrometheusRules active: $RULES"
fi

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "==> DRY-RUN complete. No changes applied."
else
  echo "==> Anomaly alert deployment complete ✅"
  echo ""
  echo "    Verify in Prometheus:"
  echo "    kubectl port-forward svc/prometheus-operated -n $NAMESPACE 9090:9090"
  echo "    Open: http://localhost:9090/rules  (search for 'CostAnomaly')"
fi
