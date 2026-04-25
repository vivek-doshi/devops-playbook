# Day One — Onboarding Guide

> **Goal:** From zero to first PR in under an hour. This guide walks the exact sequence — no archaeology of the repo structure required.

---

## Prerequisites

Before you start, verify your local toolchain. Run the checker script:

```bash
make check-prereqs
# or directly:
bash scripts/env-checker.sh
```

You need:

| Tool | Minimum version | Install |
|------|----------------|---------|
| Git | 2.40+ | [git-scm.com](https://git-scm.com) |
| Docker Desktop | 4.x | [docker.com](https://docs.docker.com/get-docker/) |
| kubectl | 1.29+ | `brew install kubectl` or [docs](https://kubernetes.io/docs/tasks/tools/) |
| kind | 0.24+ | `brew install kind` |
| Helm | 3.14+ | `brew install helm` |
| pre-commit | 3.x | `pip install pre-commit` |

> **Windows users:** All shell scripts in this repo target bash. Use WSL2 (Ubuntu 22.04+) or Git Bash. Docker Desktop must have the WSL2 backend enabled.

---

## Step 1 — Clone and bootstrap

```bash
git clone https://github.com/your-org/cicd-reference.git   # <-- CHANGE THIS
cd cicd-reference
```

Install the pre-commit hooks so quality checks run automatically before every commit and push:

```bash
make hooks
```

This runs `pre-commit install` and registers the pre-push hook. You only need to do this once per clone. See [docs/guides/pre-commit-setup.md](pre-commit-setup.md) for what the hooks check.

---

## Step 2 — Start the local Kubernetes cluster

The repo ships with a `kind` (Kubernetes in Docker) configuration that mirrors the production overlay structure: a local registry, ingress-nginx, and a `dev` namespace pre-configured.

```bash
make dev
```

This runs [`local-dev/kind/setup.sh`](../../local-dev/kind/setup.sh) which:
1. Creates a kind cluster named `devops-playbook`
2. Starts a local container registry at `localhost:5001`
3. Installs ingress-nginx via Helm
4. Creates the `dev` namespace
5. Loads a smoke-test image to confirm the registry is reachable

Expected output ends with:

```
✓ Cluster 'devops-playbook' is ready
✓ Registry is reachable at localhost:5001
✓ Ingress controller is running
```

> **Tear it down** at any time with `make teardown`. Restart cleanly with `make dev`.

---

## Step 3 — Choose your starting point

This is a reference library — you copy files from it rather than running code from it directly. Decide what you need:

| I need to… | Go to |
|------------|-------|
| Build a CI pipeline | [GETTING_STARTED.md](../../GETTING_STARTED.md) — "I need a CI pipeline" section |
| Containerise an app | `docker/<tech>/` |
| Deploy to Kubernetes | `cd/kubernetes/` + `cd/targets/<platform>/` |
| Set up Terraform | `terraform/<cloud>/` |
| Understand environments | [docs/guides/environment-strategy.md](environment-strategy.md) |
| Set up cloud auth (OIDC) | [docs/guides/github-actions-oidc.md](github-actions-oidc.md) |

---

## Step 4 — Make a change

Use short-lived branches. Branch names should follow the pattern `<type>/<description>`:

```bash
git checkout -b feat/add-nodejs-dockerfile
```

Common types: `feat`, `fix`, `docs`, `chore`, `refactor`. See [docs/guides/conventional-commits.md](conventional-commits.md) for the full reference.

### Test your change locally

Run the linter first — it catches formatting issues, trailing whitespace, and YAML errors before CI does:

```bash
make lint
```

If you're modifying Kubernetes manifests, validate them against the local cluster:

```bash
make deploy-dev
make k8s-status
```

If you're modifying Docker images:

```bash
make build           # builds the image
make build-push      # builds + pushes to local kind registry
make deploy-dev      # deploys the updated image to the kind cluster
```

---

## Step 5 — Commit and open a PR

Commit messages must follow Conventional Commits format. The pre-push hook enforces this — you'll get a clear error if the format is wrong.

```bash
# Good examples
git commit -m "feat(docker): add Node.js multi-stage Dockerfile"
git commit -m "fix(ci): correct terraform plan exit-code handling"
git commit -m "docs(onboarding): add WSL2 note for Windows users"

# Bad — will be rejected
git commit -m "stuff"
git commit -m "wip"
```

Push your branch and open a PR:

```bash
git push origin feat/add-nodejs-dockerfile
```

GitHub will pre-fill the PR description from [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md). Complete each section — especially the **checklist** and **testing done** fields.

PRs require:
- All CI checks passing (lint, tests, security scans)
- At least one approving review (see [`.github/CODEOWNERS`](../../.github/CODEOWNERS) for ownership areas)
- No unresolved PR comments

---

## Step 6 — After merge

Once your PR merges to `main`, the relevant CD workflow runs automatically. For reference changes (docs, templates), no deployment happens. For actual application changes in a forked repo using this as a base, the deploy workflow triggers.

Monitor rollout health:

```bash
make rollout-status
```

---

## Common Issues

### `kind: command not found`

```bash
# macOS
brew install kind
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
```

### `pre-commit: command not found`

```bash
pip install pre-commit
# or with pipx (avoids polluting global Python)
pipx install pre-commit
```

### Hooks fail on first run (large download)

Pre-commit downloads hook environments on first run. This can take 2–3 minutes. Subsequent runs are fast (sub-second for most hooks).

### `kubectl` can't connect after `make dev`

The kind cluster writes a kubeconfig context named `kind-devops-playbook`. Check your active context:

```bash
kubectl config current-context
# should output: kind-devops-playbook

# switch to it if needed
kubectl config use-context kind-devops-playbook
```

### Docker build fails with `permission denied`

Ensure Docker Desktop is running and your user is in the `docker` group (Linux):

```bash
sudo usermod -aG docker $USER && newgrp docker
```

---

## Key file locations

```
.
├── Makefile                          ← start here, all common commands
├── GETTING_STARTED.md                ← scenario index ("I need X, go to Y")
├── docs/guides/
│   ├── onboarding.md                 ← this file
│   ├── conventional-commits.md       ← commit message format
│   ├── branching-strategy.md         ← branching model reference
│   ├── environment-strategy.md       ← dev / staging / prod model
│   ├── github-actions-oidc.md        ← cloud auth without static secrets
│   ├── pre-commit-setup.md           ← local hook configuration
│   └── secrets-management.md        ← secrets patterns
├── .github/
│   ├── CODEOWNERS                    ← who reviews what
│   └── PULL_REQUEST_TEMPLATE.md      ← PR description template
├── local-dev/kind/                   ← local cluster setup/teardown
├── ci/                               ← CI pipeline templates
├── cd/                               ← CD manifests and GitOps
├── docker/                           ← Dockerfile templates
├── terraform/                        ← IaC modules
└── security/                         ← scanning and policy templates
```
