---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate pre-commit hook configuration that catches secrets, IaC issues, and code quality problems before code reaches CI.'
---

# Pre-Commit Hooks Generator

You are a senior DevSecOps engineer. Generate a pre-commit configuration that acts as the first line of defence before code reaches any CI pipeline.

## Context

Read these files first:
- `security/secret-detection/gitleaks.yml` — you will add a local gitleaks hook
- `security/iac-scanning/checkov.yml` (if it exists) — mirror the checks locally
- `quality/python/pyproject.toml` — Python quality tools already in use
- `quality/javascript/.eslintrc.json` and `.prettierrc` — JS quality tools in use
- `quality/.editorconfig` — formatting standards

## Your deliverables

### 1. `.pre-commit-config.yaml` (repo root)

A pre-commit configuration file with the following hook groups, each clearly commented:

**Secret detection:**
- `gitleaks` hook from `https://github.com/gitleaks/gitleaks` — local fast scan before push
- Add a comment: "Mirrors the CI gitleaks workflow but runs locally so secrets never leave the machine"

**IaC quality (only runs when relevant files change, use `files:` filter):**
- `terraform fmt` check — use the official terraform pre-commit hooks repo
- `terraform validate` — with `pass_filenames: false`
- `checkov` for Terraform files — lightweight version, not full SARIF
- `hadolint` for Dockerfiles — use the `hadolint/hadolint` pre-commit mirror

**General code quality:**
- `trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-json` from `pre-commit-hooks`
- `check-merge-conflict`
- `detect-private-key` (built-in pre-commit hook)
- `mixed-line-ending`

**Python (only when `*.py` files change):**
- `ruff` check and format
- `mypy` — with `pass_filenames: false` so it uses project config

**Shell scripts:**
- `shellcheck` for `.sh` files

### 2. `docs/guides/pre-commit-setup.md`

A setup guide covering:
- Installation: `pip install pre-commit` and `pre-commit install`
- How to run against all files: `pre-commit run --all-files`
- How to skip a hook for one commit: `SKIP=gitleaks git commit -m "..."`
- How to update hooks: `pre-commit autoupdate`
- A note explaining that this complements but does not replace CI scanning
- A troubleshooting section for the three most common failure modes (gitleaks false positive, terraform not in PATH, hadolint Docker image pull)

### 3. Update `GETTING_STARTED.md`

Add a new row to the scenario index under a "🔒 Before you commit" heading pointing to the pre-commit guide.

## Style rules

- Every hook group must have a comment block explaining what it catches and why it runs locally
- Pin all hook repos to specific revs (tags or SHAs), never floating
- The file must work on macOS, Linux, and Windows (WSL2)
- Add a note at the top of `.pre-commit-config.yaml` explaining that heavy hooks (checkov, mypy) are intentionally excluded from the default `pre-push` stage to keep commit speed fast