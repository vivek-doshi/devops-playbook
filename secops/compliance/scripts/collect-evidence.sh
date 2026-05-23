#!/usr/bin/env bash
# ============================================================
# TEMPLATE: Compliance Script - Collect Evidence
# WHEN TO USE: Build evidence package from a live cluster before audits
# PREREQUISITES: kubectl and jq configured for target cluster access
# SECRETS NEEDED: None
# WHAT TO CHANGE: output directory and namespace scope flags
# RELATED FILES: secops/compliance/scripts/generate-compliance-report.py
# MATURITY: Beta
# ============================================================

set -euo pipefail

# Run this before every audit window opens, quarterly at minimum.

OUTPUT_DIR="./evidence-$(date +%Y%m%d)"
NAMESPACE="all"

usage() {
  cat <<'USAGE'
Usage: bash secops/compliance/scripts/collect-evidence.sh [--output-dir DIR] [--namespace NAME]

Options:
  --output-dir DIR   Output evidence directory (default: ./evidence-YYYYMMDD)
  --namespace NAME   Namespace scope (default: all namespaces)
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

log() {
  echo "[collect-evidence] $*" >&2
}

require_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

write_path() {
  echo "$1"
}

require_bin kubectl
require_bin jq
require_bin sha256sum

mkdir -p \
  "$OUTPUT_DIR/kube-bench" \
  "$OUTPUT_DIR/kyverno" \
  "$OUTPUT_DIR/rbac" \
  "$OUTPUT_DIR/network-policies" \
  "$OUTPUT_DIR/pod-security" \
  "$OUTPUT_DIR/secrets" \
  "$OUTPUT_DIR/supply-chain"

log "Writing evidence to $OUTPUT_DIR"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$OUTPUT_DIR/timestamp.txt"
write_path "$OUTPUT_DIR/timestamp.txt"

log "Collecting cluster context"
kubectl config view --minify -o json > "$OUTPUT_DIR/cluster-info.json"
write_path "$OUTPUT_DIR/cluster-info.json"

log "Collecting latest kube-bench results"
LATEST_KB_CFG="$(kubectl get configmap -n secops -l scan-type=cis-benchmark -o json | jq -r '.items | sort_by(.metadata.creationTimestamp) | last | .metadata.name // empty')"
if [[ -n "$LATEST_KB_CFG" ]]; then
  kubectl get configmap "$LATEST_KB_CFG" -n secops -o json | jq -r '.data["results.json"] | fromjson' > "$OUTPUT_DIR/kube-bench/results.json"
else
  echo '{"warning":"No kube-bench results ConfigMap found"}' > "$OUTPUT_DIR/kube-bench/results.json"
fi
write_path "$OUTPUT_DIR/kube-bench/results.json"

log "Collecting Kyverno reports and policies"
if [[ "$NAMESPACE" == "all" ]]; then
  kubectl get policyreport -A -o json > "$OUTPUT_DIR/kyverno/policy-reports.json"
else
  kubectl get policyreport -n "$NAMESPACE" -o json > "$OUTPUT_DIR/kyverno/policy-reports.json"
fi
kubectl get clusterpolicy -o json > "$OUTPUT_DIR/kyverno/cluster-policies.json"

jq '{
  generatedAt: now | todate,
  failingReports: [
    .items[]
    | select((.summary.fail // 0) > 0)
    | {
        namespace: .metadata.namespace,
        name: .metadata.name,
        fail: .summary.fail,
        results: [(.results // [])[] | select(.result == "fail")]
      }
  ]
}' "$OUTPUT_DIR/kyverno/policy-reports.json" > "$OUTPUT_DIR/kyverno/violations.json"

write_path "$OUTPUT_DIR/kyverno/policy-reports.json"
write_path "$OUTPUT_DIR/kyverno/cluster-policies.json"
write_path "$OUTPUT_DIR/kyverno/violations.json"

log "Collecting RBAC evidence"
kubectl get clusterroles -o json > "$OUTPUT_DIR/rbac/clusterroles.json"
kubectl get clusterrolebindings -o json > "$OUTPUT_DIR/rbac/clusterrolebindings.json"
if [[ "$NAMESPACE" == "all" ]]; then
  kubectl get roles -A -o json > "$OUTPUT_DIR/rbac/roles-per-namespace.json"
else
  kubectl get roles -n "$NAMESPACE" -o json > "$OUTPUT_DIR/rbac/roles-per-namespace.json"
fi
write_path "$OUTPUT_DIR/rbac/clusterroles.json"
write_path "$OUTPUT_DIR/rbac/clusterrolebindings.json"
write_path "$OUTPUT_DIR/rbac/roles-per-namespace.json"

log "Collecting network policies"
if [[ "$NAMESPACE" == "all" ]]; then
  kubectl get networkpolicy -A -o json > "$OUTPUT_DIR/network-policies/all-namespaces.json"
else
  kubectl get networkpolicy -n "$NAMESPACE" -o json > "$OUTPUT_DIR/network-policies/all-namespaces.json"
fi
write_path "$OUTPUT_DIR/network-policies/all-namespaces.json"

log "Collecting pod security context metadata"
if [[ "$NAMESPACE" == "all" ]]; then
  kubectl get pods -A -o json | jq '{items: [.items[] | {
    namespace: .metadata.namespace,
    name: .metadata.name,
    podSecurityContext: .spec.securityContext,
    containers: [(.spec.containers // [])[] | {name: .name, securityContext: .securityContext}]
  }]}' > "$OUTPUT_DIR/pod-security/security-contexts.json"
else
  kubectl get pods -n "$NAMESPACE" -o json | jq '{items: [.items[] | {
    namespace: .metadata.namespace,
    name: .metadata.name,
    podSecurityContext: .spec.securityContext,
    containers: [(.spec.containers // [])[] | {name: .name, securityContext: .securityContext}]
  }]}' > "$OUTPUT_DIR/pod-security/security-contexts.json"
fi
write_path "$OUTPUT_DIR/pod-security/security-contexts.json"

log "Collecting ExternalSecret status metadata only"
# Explicit safety guard: never collect Secret data values, only ExternalSecret metadata and status.
if kubectl api-resources | grep -q '^externalsecrets'; then
  if [[ "$NAMESPACE" == "all" ]]; then
    kubectl get externalsecret -A -o json | jq '{items: [.items[] | {
      namespace: .metadata.namespace,
      name: .metadata.name,
      refreshInterval: .spec.refreshInterval,
      secretStoreRef: .spec.secretStoreRef,
      targetSecretName: .spec.target.name,
      conditions: .status.conditions,
      refreshTime: .status.refreshTime,
      syncedResourceVersion: .status.syncedResourceVersion
    }]}' > "$OUTPUT_DIR/secrets/externalsecrets-status.json"
  else
    kubectl get externalsecret -n "$NAMESPACE" -o json | jq '{items: [.items[] | {
      namespace: .metadata.namespace,
      name: .metadata.name,
      refreshInterval: .spec.refreshInterval,
      secretStoreRef: .spec.secretStoreRef,
      targetSecretName: .spec.target.name,
      conditions: .status.conditions,
      refreshTime: .status.refreshTime,
      syncedResourceVersion: .status.syncedResourceVersion
    }]}' > "$OUTPUT_DIR/secrets/externalsecrets-status.json"
  fi
else
  log "ExternalSecret CRD not found; writing empty metadata evidence"
  echo '{"items":[],"note":"ExternalSecret CRD not installed"}' > "$OUTPUT_DIR/secrets/externalsecrets-status.json"
fi
write_path "$OUTPUT_DIR/secrets/externalsecrets-status.json"

log "Collecting supply chain policy report subset"
jq '{
  items: [
    .items[]
    | {
        namespace: .metadata.namespace,
        name: .metadata.name,
        results: [(.results // [])[]
          | select(
              (.policy // "")
              | test("verify-image-signature|verify-sbom-attestation|verify-slsa-provenance")
            )
        ]
      }
    | select((.results | length) > 0)
  ]
}' "$OUTPUT_DIR/kyverno/policy-reports.json" > "$OUTPUT_DIR/supply-chain/policy-reports.json"
write_path "$OUTPUT_DIR/supply-chain/policy-reports.json"

log "Building tamper-evident manifest"
MANIFEST_PATH="$OUTPUT_DIR/manifest.json"
{
  echo '{'
  echo '  "generatedAt": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'",'
  echo '  "outputDir": "'"$OUTPUT_DIR"'",'
  echo '  "files": ['

  FIRST=true
  while IFS= read -r FILE; do
    [[ "$FILE" == "$MANIFEST_PATH" ]] && continue
    HASH="$(sha256sum "$FILE" | awk '{print $1}')"
    REL="${FILE#$OUTPUT_DIR/}"
    if [[ "$FIRST" == true ]]; then
      FIRST=false
    else
      echo '    ,'
    fi
    printf '    {"path":"%s","sha256":"%s"}' "$REL" "$HASH"
  done < <(find "$OUTPUT_DIR" -type f | sort)

  echo
  echo '  ]'
  echo '}'
} > "$MANIFEST_PATH"

write_path "$MANIFEST_PATH"
log "Evidence collection complete"
