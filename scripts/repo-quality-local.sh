#!/usr/bin/env bash
set -euo pipefail

# Run the repository quality gate locally with checks that mirror CI.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ACTIONLINT_VERSION="1.7.3"
KUBECONFORM_VERSION="0.6.7"
CONFTEST_VERSION="0.57.0"

TOOLS_DIR="$ROOT_DIR/.tmp/repo-quality-tools"
mkdir -p "$TOOLS_DIR"
export PATH="$TOOLS_DIR:$PATH"

step() {
  echo ""
  echo "==> $1"
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    exit 1
  fi
}

install_actionlint() {
  if command -v actionlint >/dev/null 2>&1; then
    return
  fi
  step "Installing actionlint ${ACTIONLINT_VERSION}"
  curl -sSL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash -s -- "$ACTIONLINT_VERSION"
  mv ./actionlint "$TOOLS_DIR/actionlint"
  chmod +x "$TOOLS_DIR/actionlint"
}

install_kubeconform() {
  if command -v kubeconform >/dev/null 2>&1; then
    return
  fi
  step "Installing kubeconform ${KUBECONFORM_VERSION}"
  curl -sSL -o /tmp/kubeconform.tar.gz "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz"
  tar -xzf /tmp/kubeconform.tar.gz -C /tmp
  mv /tmp/kubeconform "$TOOLS_DIR/kubeconform"
  chmod +x "$TOOLS_DIR/kubeconform"
}

install_conftest() {
  if command -v conftest >/dev/null 2>&1; then
    return
  fi
  step "Installing conftest ${CONFTEST_VERSION}"
  curl -sSL -o /tmp/conftest.tar.gz "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz"
  tar -xzf /tmp/conftest.tar.gz -C /tmp
  mv /tmp/conftest "$TOOLS_DIR/conftest"
  chmod +x "$TOOLS_DIR/conftest"
}

install_lychee() {
  if command -v lychee >/dev/null 2>&1; then
    if lychee --version >/dev/null 2>&1; then
      return
    fi
  fi

  rm -f "$TOOLS_DIR/lychee"

  local lychee_version="0.24.2"
  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    armv7l|armv7) arch="armv7" ;;
    *)
      echo "Unsupported architecture for lychee: $(uname -m)"
      exit 1
      ;;
  esac

  local asset="lychee-${arch}-unknown-linux-musl.tar.gz"
  local tag="lychee-v${lychee_version}"
  local url="https://github.com/lycheeverse/lychee/releases/download/${tag}/${asset}"

  step "Installing lychee v${lychee_version}"
  curl -sSL -o /tmp/lychee.tar.gz "$url"
  mkdir -p /tmp/lychee-bin
  tar -xzf /tmp/lychee.tar.gz -C /tmp/lychee-bin
  local extracted_dir="/tmp/lychee-bin/lychee-${arch}-unknown-linux-musl"
  if [[ ! -x "${extracted_dir}/lychee" ]]; then
    echo "Expected lychee binary not found in archive: ${extracted_dir}/lychee"
    exit 1
  fi
  mv "${extracted_dir}/lychee" "$TOOLS_DIR/lychee"
  chmod +x "$TOOLS_DIR/lychee"
}

step "Checking prerequisites"
require_cmd curl
require_cmd python3
require_cmd helm
require_cmd terraform
require_cmd npm
require_cmd npx
install_actionlint
install_kubeconform
install_conftest
install_lychee

step "Markdown links"
lychee --config .lychee.toml docs/**/*.md README.md GETTING_STARTED.md

step "Actionlint"
actionlint -color

step "Yamllint"
python3 -m pip install --quiet yamllint==1.35.1
yamllint -c .yamllint.yml .

step "Kubeconform"
mapfile -t kube_files < <(find cd/kubernetes -type f \( -name "*.yml" -o -name "*.yaml" \) | grep -Ev 'kustomization\.ya?ml$|_test\.ya?ml$' || true)
if [[ ${#kube_files[@]} -gt 0 ]]; then
  kubeconform --strict --kubernetes-version 1.29.0 --ignore-missing-schemas --summary --output pretty "${kube_files[@]}"
else
  echo "No Kubernetes manifests found under cd/kubernetes/."
fi

step "Helm lint + template"
shopt -s nullglob
charts=()
for dir in cd/helm/*/; do
  if [[ -f "${dir}Chart.yaml" ]]; then
    charts+=("$dir")
  fi
done
if [[ ${#charts[@]} -eq 0 ]]; then
  echo "No Helm charts found under cd/helm/."
else
  for chart in "${charts[@]}"; do
    chart_name="$(basename "$chart")"
    helm lint "$chart" --strict
    helm template "$chart_name" "$chart" | kubeconform --strict --kubernetes-version 1.29.0 --ignore-missing-schemas --summary --output pretty -
  done
fi

step "Terraform init/fmt/validate"
modules=(aws-eks azure-aks gcp-gke aws-lambda aws-ecs azure-app-service)
for module in "${modules[@]}"; do
  pushd "terraform/$module" >/dev/null
  terraform init -backend=false
  terraform fmt -check -recursive
  terraform validate
  popd >/dev/null
done

step "Conftest"
conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes --output table
helm template webapp cd/helm/webapp/ | conftest test - --policy policy/conftest/kubernetes --output table

step "Catalog validate"
python3 -m pip install --quiet pyyaml
python3 catalog/scripts/validate-catalog.py --strict --skip-url-check

step "Website build"
if [[ -d website ]]; then
  npm --prefix website ci
  npm --prefix website run build
else
  echo "Warning: website/ not found, skipping website build"
fi

echo ""
echo "Repo quality gate checks passed locally."
