#!/usr/bin/env bash
# finops/scripts/deploy-budget-alerts.sh
# Read finops/config/budgets.yaml and generate/apply Prometheus recording rules
# that expose finops_budget_threshold metrics for each cost center.
#
# Usage:
#   ./deploy-budget-alerts.sh
#   ./deploy-budget-alerts.sh --config finops/config/budgets.yaml
#   ./deploy-budget-alerts.sh --dry-run

set -euo pipefail

CONFIG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/budgets.yaml"
DRY_RUN=false
NAMESPACE="monitoring"
RULE_NAME="finops-budget-thresholds"
FAILURES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)   CONFIG_FILE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --namespace) NAMESPACE="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--config PATH] [--dry-run] [--namespace NS]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Budget config not found: $CONFIG_FILE"
  exit 1
fi

echo "==> Generating budget threshold PrometheusRule from $CONFIG_FILE ..."

# Extract budgets from YAML using Python
BUDGET_JSON=$(python3 -c "
import sys, yaml, json
with open('$CONFIG_FILE') as f:
    cfg = yaml.safe_load(f)
print(json.dumps(cfg.get('budgets', [])))
" 2>/dev/null) || {
  echo "ERROR: Failed to parse $CONFIG_FILE. Ensure 'pyyaml' is installed: pip install pyyaml"
  exit 1
}

# Build PrometheusRule YAML dynamically
RULES=$(python3 -c "
import json, sys
budgets = json.loads('$BUDGET_JSON'.replace(\"'\", '\"'))

rules = []
for b in budgets:
    cc = b['cost_center']
    threshold = b['monthly_threshold_usd']
    # Hourly equivalent (threshold / 730)
    hourly = round(threshold / 730, 4)
    rules.append(f'''        - record: finops_budget_threshold
          labels:
            cost_center: \"{cc}\"
          expr: \"{threshold}\"
        - record: finops_budget_hourly_threshold
          labels:
            cost_center: \"{cc}\"
          expr: \"{hourly}\"
''')
print(''.join(rules).rstrip())
")

MANIFEST="apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: $RULE_NAME
  namespace: $NAMESPACE
  labels:
    app: kube-prometheus-stack
    release: kube-prometheus-stack
    finops.org/component: budget-thresholds
spec:
  groups:
    - name: finops.budget.thresholds
      interval: 5m
      rules:
$RULES"

echo "==> Generated PrometheusRule: $RULE_NAME"
echo ""
echo "$MANIFEST"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "==> DRY-RUN: No changes applied."
  exit 0
fi

if ! kubectl get crd prometheusrules.monitoring.coreos.com &>/dev/null; then
  echo "ERROR: PrometheusRule CRD not found. Ensure kube-prometheus-stack is installed."
  exit 1
fi

echo "==> Applying to namespace $NAMESPACE ..."
echo "$MANIFEST" | kubectl apply -f -

echo ""
echo "==> Budget threshold rules applied successfully."
echo "    Verify: kubectl get prometheusrule -n $NAMESPACE $RULE_NAME"
