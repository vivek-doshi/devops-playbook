# syntax=docker/dockerfile:1.7

ARG VARIANT=ubuntu-22.04
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

LABEL maintainer="Platform Engineering <platform@example.com>" \
      devops-playbook.last-updated="2026-04-23"

ARG TARGETARCH
ARG TERRAFORM_VERSION=v1.14.9
ARG KUBECTL_VERSION=v1.36.0
ARG HELM_VERSION=v4.1.4
ARG K9S_VERSION=v0.50.18
ARG KIND_VERSION=v0.31.0
ARG PULUMI_VERSION=v3.231.0
ARG NODE_MAJOR=20
ARG PYTHON_VERSION=3.12
ARG PRE_COMMIT_VERSION=4.6.0
ARG CHECKOV_VERSION=3.2.524
ARG TFSEC_VERSION=v1.28.14
ARG HADOLINT_VERSION=v2.14.0
ARG GITLEAKS_VERSION=v8.30.1
ARG TRUFFLEHOG_VERSION=v3.95.2
ARG JQ_VERSION=jq-1.8.1
ARG YQ_VERSION=v4.53.2
ARG KUBECTX_VERSION=v0.11.0
ARG STERN_VERSION=v1.33.1
ARG AWS_CLI_VERSION=2.34.35
ARG AZURE_CLI_VERSION=2.85.0-1~jammy
ARG GCLOUD_VERSION=565.0.0-0
ARG OH_MY_ZSH_REF=349b9e49ced7682e27927ffb34b6522f011f3e74
ARG PIP_VERSION=24.3.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PULUMI_HOME=/usr/local/pulumi

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      apt-transport-https \
      ca-certificates \
      curl \
      git \
      gnupg \
      less \
      lsb-release \
      procps \
      software-properties-common \
      sudo \
      tar \
      unzip \
      xz-utils \
      zip \
      zsh \
 && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/hashicorp.list \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/azure-cli.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/azure-cli.gpg] https://packages.microsoft.com/repos/azure-cli/ $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/azure-cli.list \
 && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/google-cloud.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/google-cloud.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list \
 && add-apt-repository -y ppa:deadsnakes/ppa \
 && apt-get update \
 && \
   # Terraform underpins every example in terraform/ and the local IaC validation workflow.
   apt-get install --no-install-recommends -y terraform=${TERRAFORM_VERSION#v}-1 \
 && \
   # Node 20 powers the website and the Node.js-based Pulumi projects under cd/pulumi/.
   apt-get install --no-install-recommends -y nodejs \
 && \
   # Azure CLI authenticates deployments and local experiments against the Azure targets in this repo.
   apt-get install --no-install-recommends -y azure-cli=${AZURE_CLI_VERSION} \
 && \
   # Google Cloud SDK is required for the GKE and GCP deployment targets and observability examples.
   apt-get install --no-install-recommends -y google-cloud-cli=${GCLOUD_VERSION} \
 && \
   # Python 3.12 matches the shared ruff and mypy configuration in quality/python/pyproject.toml.
   apt-get install --no-install-recommends -y \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) BIN_ARCH="amd64"; HADOLINT_ARCH="x86_64"; GITLEAKS_ARCH="x64"; AWS_ARCH="x86_64" ;; \
      arm64) BIN_ARCH="arm64"; HADOLINT_ARCH="arm64"; GITLEAKS_ARCH="arm64"; AWS_ARCH="aarch64" ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    temp_dir="$(mktemp -d)"; \
    cd "${temp_dir}"; \
    # kubectl manages clusters and validates manifests across cd/kubernetes and local-dev workflows.
    curl -fsSLo kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BIN_ARCH}/kubectl"; \
    install -m 0755 kubectl /usr/local/bin/kubectl; \
    # Helm renders and upgrades the chart examples in cd/helm and observability installs.
    cat <<'HELM_SCRIPT' > install-helm.sh
#!/usr/bin/env bash
set -euo pipefail
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${BIN_ARCH}.tar.gz" | tar -xz
install -m 0755 "linux-${BIN_ARCH}/helm" /usr/local/bin/helm
HELM_SCRIPT
    chmod 0755 install-helm.sh; \
    HELM_VERSION="${HELM_VERSION}" BIN_ARCH="${BIN_ARCH}" ./install-helm.sh; \
    # k9s gives fast cluster inspection while iterating on Kubernetes manifests and Helm charts.
    curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${BIN_ARCH}.tar.gz" | tar -xz k9s; \
    install -m 0755 k9s /usr/local/bin/k9s; \
    # kind provides disposable local clusters for testing manifests before pushing.
    curl -fsSLo kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${BIN_ARCH}"; \
    install -m 0755 kind /usr/local/bin/kind; \
    # Pulumi is needed for the Node.js infrastructure projects under cd/pulumi.
    curl -fsSL https://get.pulumi.com | sh -s -- --version "${PULUMI_VERSION#v}"; \
    ln -sf "${PULUMI_HOME}/bin/pulumi" /usr/local/bin/pulumi; \
    # jq is the default JSON inspection tool for workflow debugging and script automation in this repo.
    curl -fsSLo jq "https://github.com/jqlang/jq/releases/download/${JQ_VERSION}/jq-linux-${BIN_ARCH}"; \
    install -m 0755 jq /usr/local/bin/jq; \
    # yq is used for YAML editing across Kubernetes, CI, and observability configuration.
    curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${BIN_ARCH}"; \
    chmod 0755 /usr/local/bin/yq; \
    # tfsec provides Terraform-specific cloud misconfiguration checks alongside Checkov.
    curl -fsSLo /usr/local/bin/tfsec "https://github.com/aquasecurity/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-${BIN_ARCH}"; \
    chmod 0755 /usr/local/bin/tfsec; \
    # Hadolint reviews Dockerfiles across docker/ before container builds reach CI.
    curl -fsSLo /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-linux-${HADOLINT_ARCH}"; \
    chmod 0755 /usr/local/bin/hadolint; \
    # Gitleaks mirrors the repository's secret detection policy during local development.
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_${GITLEAKS_ARCH}.tar.gz" | tar -xz gitleaks; \
    install -m 0755 gitleaks /usr/local/bin/gitleaks; \
    # TruffleHog complements Gitleaks with verified secret checks and deeper history scanning.
    curl -fsSL "https://github.com/trufflesecurity/trufflehog/releases/download/${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION#v}_linux_${BIN_ARCH}.tar.gz" | tar -xz trufflehog; \
    install -m 0755 trufflehog /usr/local/bin/trufflehog; \
    # kubectx and kubens speed up context and namespace switching when testing multiple clusters.
    curl -fsSLo /usr/local/bin/kubectx "https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubectx"; \
    curl -fsSLo /usr/local/bin/kubens "https://raw.githubusercontent.com/ahmetb/kubectx/${KUBECTX_VERSION}/kubens"; \
    chmod 0755 /usr/local/bin/kubectx /usr/local/bin/kubens; \
    # Stern tails logs from many pods at once, which is useful for local Kubernetes debugging.
    curl -fsSL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_${BIN_ARCH}.tar.gz" | tar -xz stern; \
    install -m 0755 stern /usr/local/bin/stern; \
    # AWS CLI v2 supports the AWS deployment targets and Terraform modules in this repository.
    curl -fsSLo awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip"; \
    unzip -q awscliv2.zip; \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update; \
    rm -rf "${temp_dir}"

RUN curl -fsSLo /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py \
 && python${PYTHON_VERSION} /tmp/get-pip.py "pip==${PIP_VERSION}" \
 && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python \
 && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3 \
 && ln -sf /usr/local/bin/pip${PYTHON_VERSION} /usr/local/bin/pip \
 && ln -sf /usr/local/bin/pip${PYTHON_VERSION} /usr/local/bin/pip3 \
 && \
    # pre-commit installs the repository's local guardrails before code reaches CI.
    # Checkov mirrors the repository's IaC policy checks without the CI-only SARIF upload path.
 && python${PYTHON_VERSION} -m pip install --no-cache-dir \
      pre-commit==${PRE_COMMIT_VERSION} \
      checkov==${CHECKOV_VERSION} \
 && rm -f /tmp/get-pip.py

RUN mkdir -p /usr/local/share/devops-playbook \
 && cat <<'BASH_PROMPT' > /usr/local/share/devops-playbook/bash-prompt.sh
__devops_git_branch() {
  git branch --show-current 2>/dev/null
}

__devops_kube_context() {
  kubectl config current-context 2>/dev/null || echo "no-k8s"
}

__devops_kube_namespace() {
  local namespace
  namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)"
  if [ -z "${namespace}" ]; then
    echo "default"
  else
    echo "${namespace}"
  fi
}

export PS1='\[\e[36m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\] \[\e[33m\]$(__devops_git_branch)\[\e[0m\] \[\e[35m\][$(__devops_kube_context):$(__devops_kube_namespace)]\[\e[0m\]\\$ '
BASH_PROMPT
 && cat <<'ZSH_PROMPT' > /usr/local/share/devops-playbook/zsh-prompt.zsh
setopt PROMPT_SUBST

devops_git_branch() {
  git branch --show-current 2>/dev/null
}

devops_kube_context() {
  kubectl config current-context 2>/dev/null || echo "no-k8s"
}

devops_kube_namespace() {
  local namespace
  namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)"
  if [[ -z "${namespace}" ]]; then
    echo "default"
  else
    echo "${namespace}"
  fi
}

PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %F{yellow}$(devops_git_branch)%f %F{magenta}[$(devops_kube_context):$(devops_kube_namespace)]%f %# '
ZSH_PROMPT

USER vscode

RUN git clone https://github.com/ohmyzsh/ohmyzsh.git /home/vscode/.oh-my-zsh \
 && cd /home/vscode/.oh-my-zsh \
 && git checkout ${OH_MY_ZSH_REF} \
 && cat <<'BASHRC' >> /home/vscode/.bashrc

if [ -f /usr/local/share/devops-playbook/bash-prompt.sh ]; then
  source /usr/local/share/devops-playbook/bash-prompt.sh
fi
BASHRC
 && cat <<'ZSHRC' > /home/vscode/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git kubectl terraform helm docker)

source "$ZSH/oh-my-zsh.sh"

if [ -f /usr/local/share/devops-playbook/zsh-prompt.zsh ]; then
  source /usr/local/share/devops-playbook/zsh-prompt.zsh
fi
ZSHRC
