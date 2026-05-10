#!/usr/bin/env bash
# finops/scripts/deploy-dashboards.sh
# Deploy all FinOps Grafana dashboards via the Grafana HTTP API.
# Usage:
#   ./deploy-dashboards.sh [--grafana-url URL] [--api-key KEY] [--folder FOLDER]
#
# Environment variables (fallback):
#   GRAFANA_URL      (default: http://grafana.monitoring.svc.cluster.local:3000)
#   GRAFANA_API_KEY  (required if --api-key not provided)
#   GRAFANA_FOLDER   (default: FinOps)

set -euo pipefail

# ─── defaults ────────────────────────────────────────────────────────────────
GRAFANA_URL="${GRAFANA_URL:-http://grafana.monitoring.svc.cluster.local:3000}"
GRAFANA_API_KEY="${GRAFANA_API_KEY:-}"
GRAFANA_FOLDER="${GRAFANA_FOLDER:-FinOps}"
DASHBOARDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dashboards" && pwd)"
FOLDER_UID=""
FAILURES=0
SUCCESSES=0

# ─── argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --grafana-url) GRAFANA_URL="$2"; shift 2 ;;
    --api-key)     GRAFANA_API_KEY="$2"; shift 2 ;;
    --folder)      GRAFANA_FOLDER="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--grafana-url URL] [--api-key KEY] [--folder FOLDER]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ─── validation ───────────────────────────────────────────────────────────────
if [[ -z "$GRAFANA_API_KEY" ]]; then
  echo "ERROR: GRAFANA_API_KEY is required. Set the env var or use --api-key."
  exit 1
fi

if [[ ! -d "$DASHBOARDS_DIR" ]]; then
  echo "ERROR: Dashboards directory not found: $DASHBOARDS_DIR"
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $GRAFANA_API_KEY"
CONTENT_HEADER="Content-Type: application/json"

# ─── helpers ──────────────────────────────────────────────────────────────────
grafana_request() {
  local method="$1" path="$2" data="${3:-}"
  if [[ -n "$data" ]]; then
    curl -s -f -X "$method" \
      -H "$AUTH_HEADER" -H "$CONTENT_HEADER" \
      -d "$data" \
      "${GRAFANA_URL}${path}"
  else
    curl -s -f -X "$method" \
      -H "$AUTH_HEADER" -H "$CONTENT_HEADER" \
      "${GRAFANA_URL}${path}"
  fi
}

# ─── check Grafana connectivity ───────────────────────────────────────────────
echo "==> Checking Grafana connectivity at $GRAFANA_URL ..."
if ! grafana_request GET "/api/health" > /dev/null 2>&1; then
  echo "ERROR: Cannot reach Grafana at $GRAFANA_URL. Check URL and network."
  exit 1
fi
echo "    Grafana is reachable."

# ─── create/find folder ───────────────────────────────────────────────────────
echo "==> Ensuring folder '$GRAFANA_FOLDER' exists ..."

EXISTING_FOLDER=$(grafana_request GET "/api/folders" | \
  python3 -c "import sys, json; folders=json.load(sys.stdin); \
    matches=[f for f in folders if f['title']=='${GRAFANA_FOLDER}']; \
    print(matches[0]['uid'] if matches else '')" 2>/dev/null || true)

if [[ -n "$EXISTING_FOLDER" ]]; then
  FOLDER_UID="$EXISTING_FOLDER"
  echo "    Found existing folder UID: $FOLDER_UID"
else
  FOLDER_RESP=$(grafana_request POST "/api/folders" \
    "{\"title\": \"${GRAFANA_FOLDER}\"}")
  FOLDER_UID=$(echo "$FOLDER_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin)['uid'])")
  echo "    Created folder UID: $FOLDER_UID"
fi

# ─── deploy dashboards ────────────────────────────────────────────────────────
echo ""
echo "==> Deploying dashboards from $DASHBOARDS_DIR ..."

DASHBOARD_FILES=$(find "$DASHBOARDS_DIR" -name "*.json" | sort)

if [[ -z "$DASHBOARD_FILES" ]]; then
  echo "    No dashboard JSON files found in $DASHBOARDS_DIR."
  exit 0
fi

for dashboard_file in $DASHBOARD_FILES; do
  filename=$(basename "$dashboard_file")
  echo ""
  echo "  -> Importing: $filename"

  # Validate JSON syntax
  if ! python3 -c "import json, sys; json.load(sys.stdin)" < "$dashboard_file" 2>/dev/null; then
    echo "     ERROR: Invalid JSON in $filename. Skipping."
    FAILURES=$((FAILURES + 1))
    continue
  fi

  # Build the import payload: wrap dashboard JSON in the expected structure
  PAYLOAD=$(python3 -c "
import json, sys
with open('$dashboard_file') as f:
    dash = json.load(f)

# Remove __inputs and __requires which are only for export format
dash.pop('__inputs', None)
dash.pop('__requires', None)
dash['id'] = None   # Let Grafana assign the ID

payload = {
  'dashboard': dash,
  'folderId': 0,
  'folderUid': '$FOLDER_UID',
  'overwrite': True,
  'message': 'Deployed by deploy-dashboards.sh'
}
print(json.dumps(payload))
")

  RESPONSE=$(grafana_request POST "/api/dashboards/db" "$PAYLOAD" 2>&1) || true

  if echo "$RESPONSE" | python3 -c "import sys, json; r=json.load(sys.stdin); exit(0 if r.get('status')=='success' else 1)" 2>/dev/null; then
    DASH_URL=$(echo "$RESPONSE" | python3 -c "import sys, json; r=json.load(sys.stdin); print(r.get('url',''))")
    echo "     OK — ${GRAFANA_URL}${DASH_URL}"
    SUCCESSES=$((SUCCESSES + 1))
  else
    echo "     ERROR importing $filename: $RESPONSE"
    FAILURES=$((FAILURES + 1))
  fi
done

# ─── summary ──────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo " Dashboard Deployment Summary"
echo "========================================"
echo "  Succeeded : $SUCCESSES"
echo "  Failed    : $FAILURES"
echo "========================================"

if [[ $FAILURES -gt 0 ]]; then
  echo "Some dashboards failed to import. Review errors above."
  exit 1
fi

echo "All dashboards deployed successfully!"
echo "View them at: ${GRAFANA_URL}/dashboards"
