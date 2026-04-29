#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

required_tools=(
  terraform
  kubectl
  helm
  k9s
  kind
  pulumi
  node
  npm
  python3
  pre-commit
  checkov
  tfsec
  hadolint
  gitleaks
  trufflehog
  jq
  yq
  kubectx
  kubens
  stern
  aws
  az
  gcloud
)

missing_tools=()

for tool in "${required_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    missing_tools+=("${tool}")
  fi
done

if command -v npm >/dev/null 2>&1; then
  npm install --global @pulumi/pulumi >/dev/null 2>&1
fi

echo "==> Installing helm plugins..."
if helm plugin list | grep -q '^diff'; then
  echo "    helm-diff already installed, skipping"
else
  helm plugin install https://github.com/databus23/helm-diff
fi

if helm plugin list | grep -q '^secrets'; then
  echo "    helm-secrets already installed, skipping"
else
  helm plugin install https://github.com/jkroepke/helm-secrets
fi

if [ -f .pre-commit-config.yaml ] && command -v pre-commit >/dev/null 2>&1; then
  pre-commit install
  pre-commit install --hook-type pre-push
fi

# Git cannot consume .editorconfig directly, so align the repository checkout behaviour with its LF policy.
git config --global --add safe.directory "${repo_root}"
git config --global core.autocrlf input
git config --global core.eol lf

print_version() {
  case "$1" in
    terraform) terraform version -json | jq -r '.terraform_version' ;;
    kubectl) kubectl version --client=true --output=yaml | awk -F': ' '/gitVersion/ {print $2; exit}' ;;
    helm) helm version --template '{{ .Version }}' ;;
    k9s) k9s version -s ;;
    kind) kind version ;;
    pulumi) pulumi version ;;
    node) node --version ;;
    python3) python3 --version | awk '{print $2}' ;;
    pre-commit) pre-commit --version | awk '{print $2}' ;;
    checkov) checkov --version | awk '{print $2}' ;;
    tfsec) tfsec --version | awk '{print $2}' ;;
    hadolint) hadolint --version | awk '{print $4}' ;;
    gitleaks) gitleaks version ;;
    trufflehog) trufflehog --version ;;
    jq) jq --version ;;
    yq) yq --version | awk '{print $4}' ;;
    stern) stern --version ;;
    aws) aws --version 2>&1 | awk -F'[/ ]' '{print $2}' ;;
    az) az version --output json | jq -r '.["azure-cli"]' ;;
    gcloud) gcloud version --format='value(Google Cloud SDK)' ;;
    *) echo "n/a" ;;
  esac
}

echo
echo "DevOps Playbook devcontainer is ready."
echo
echo "Installed tool versions:"
for tool in terraform kubectl helm kind pulumi node python3 pre-commit checkov tfsec hadolint gitleaks trufflehog aws az gcloud; do
  if command -v "${tool}" >/dev/null 2>&1; then
    printf '  - %-10s %s\n' "${tool}" "$(print_version "${tool}")"
  fi
done

if [ "${#missing_tools[@]}" -gt 0 ]; then
  echo
  echo "Missing required tools on PATH:" >&2
  printf '  - %s\n' "${missing_tools[@]}" >&2
  exit 1
fi

echo
echo "All required CLI tools are available on PATH."
