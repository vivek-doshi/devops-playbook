---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'runCommands', 'search']
description: 'Generate a devcontainer configuration giving developers a fully equipped DevOps environment in VS Code or GitHub Codespaces.'
---

# Dev Container Generator

You are a senior platform engineer. Generate a devcontainer configuration so any developer can open this repo and have every DevOps tool pre-installed and pre-configured within 5 minutes.

## Context

Read these files first:
- `README.md` — understand the full scope of technologies in this repo
- `terraform/` directories — identify Terraform provider versions
- `cd/pulumi/` — identify Pulumi runtime (Node.js/TypeScript)
- `.github/workflows/deploy.yml` — identify Node.js version in use
- `quality/python/pyproject.toml` — identify Python version

## Your deliverables

### 1. `.devcontainer/devcontainer.json`

A devcontainer configuration that:
- Uses `mcr.microsoft.com/devcontainers/base:ubuntu-22.04` as the base
- References `.devcontainer/Dockerfile` for tool installation
- Sets `postCreateCommand` to run a setup script
- Configures the following VS Code extensions (add each with a comment explaining why):
  - `hashicorp.terraform`
  - `ms-kubernetes-tools.vscode-kubernetes-tools`
  - `redhat.vscode-yaml`
  - `ms-azuretools.vscode-docker`
  - `github.copilot`
  - `github.copilot-chat`
  - `timonwong.shellcheck`
  - `foxundermoon.shell-format`
  - `ms-python.python`
  - `charliermarsh.ruff`
  - `esbenp.prettier-vscode`
  - `dbaeumer.vscode-eslint`
  - `eamodio.gitlens`
  - `mhutchie.git-graph`
- Sets VS Code settings:
  - Auto-format on save for all supported file types
  - `editor.rulers: [100]` to match repo line length standard
  - Terminal defaults to bash
- Sets `remoteUser: vscode`
- Forwards ports: 3000, 8000, 8080, 9090 (Prometheus), 3100 (Loki), 16686 (Jaeger)

### 2. `.devcontainer/Dockerfile`

A multi-stage-friendly Dockerfile that installs:

**Core tools (with pinned versions and a comment on each explaining its purpose):**
- `terraform` — pin to latest stable, install via HashiCorp apt repo
- `kubectl` — pin to latest stable
- `helm` — pin to latest stable, install via script
- `k9s` — install via GitHub releases
- `kind` — for local Kubernetes clusters
- `pulumi` — via the official install script
- `node` 20.x — via NodeSource
- `python` 3.12 — via deadsnakes PPA
- `pre-commit` — via pip
- `checkov` — via pip
- `tfsec` — via GitHub releases
- `hadolint` — via GitHub releases
- `gitleaks` — via GitHub releases
- `trufflehog` — via GitHub releases
- `jq` and `yq` — essential JSON/YAML tools
- `kubectx` and `kubens` — context and namespace switching
- `stern` — multi-pod log tailing
- AWS CLI v2
- Azure CLI
- Google Cloud SDK

**Shell configuration:**
- Install `oh-my-zsh` with the following plugins: git, kubectl, terraform, helm, docker
- Set a clean PS1 that shows: current git branch, kubernetes context, namespace

### 3. `.devcontainer/scripts/post-create.sh`

A setup script that runs after container creation:
- Installs npm global tools: `@pulumi/pulumi` type stubs
- Runs `pre-commit install` if `.pre-commit-config.yaml` exists
- Configures git to use the repo's `.editorconfig`
- Prints a welcome message listing installed tool versions
- Checks that all required CLI tools are on PATH and reports any missing ones

### 4. `.devcontainer/README.md`

A short guide explaining:
- How to open in VS Code: "Reopen in Container"
- How to open in GitHub Codespaces
- What is pre-installed and why
- How to add project-specific tools without modifying the shared Dockerfile (use `postCreateCommand` overrides)
- Expected first-launch time (approximately 5-8 minutes on first build, <30 seconds after)

## Style rules

- Every tool installation in the Dockerfile must have a comment explaining what it is used for in this repo
- All versions must be explicitly pinned — no `latest` tags anywhere
- The container must work on both amd64 and arm64 (Apple Silicon) — use multi-arch base images and check binary downloads
- Add a `LABEL` in the Dockerfile with maintainer and last-updated metadata
- The total image size should be minimised — use `--no-install-recommends` for apt and clean up in the same RUN layer