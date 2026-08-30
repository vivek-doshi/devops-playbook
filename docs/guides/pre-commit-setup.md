# Pre-Commit Setup

Use pre-commit as the first local gate before anything reaches CI. It complements the repository's CI scanning and quality workflows, but it does not replace them: CI still provides the authoritative shared check in a clean environment.

## Install

Install pre-commit and register both commit-time and push-time hooks:

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type pre-push
```

On Windows, run the hooks from WSL2 if your local toolchain for Terraform, Docker, or shell tooling already lives there.

## Common Commands

Run the configured hooks against all files:

```bash
pre-commit run --all-files
```

Skip a hook for a single commit when you have a documented reason:

```bash
SKIP=gitleaks git commit -m "explain the exception"
```

Update pinned hook revisions after review:

```bash
pre-commit autoupdate
```

## Task / Make Shortcuts

`Taskfile.yml` and `Makefile` wrap the hooks above instead of re-implementing tool calls, so the
pinned versions and configs in `.pre-commit-config.yaml` stay the single source of truth:

| Shortcut | Delegates to |
|---|---|
| `make lint` / `task quality:pre-commit-run` | `pre-commit run --all-files` |
| `make lint-staged` | `pre-commit run` (staged files only) |
| `make hooks` | `pre-commit install` + `pre-commit install --hook-type pre-push` |
| `task quality:lint-yaml` | `pre-commit run yamllint --all-files` |
| `task quality:lint-terraform` / `task tf:lint` | `pre-commit run terraform_fmt/terraform_validate/terraform_tflint --all-files` |
| `task tf:fmt-check` | `pre-commit run terraform_fmt --all-files` |
| `task docker:lint-dockerfiles` | `pre-commit run hadolint --all-files` |
| `task quality:lint-python` | `pre-commit run ruff-check/mypy --all-files` |

## What Runs Locally

The root configuration in [../../.pre-commit-config.yaml](../../.pre-commit-config.yaml) combines four layers:

1. Fast repository hygiene checks for whitespace, JSON, YAML, merge conflicts, and private keys.
2. Secret detection with Gitleaks before push.
3. YAML style checks with yamllint, using the same [../../.yamllint.yml](../../.yamllint.yml) rules as the CI Yamllint job.
4. Infrastructure checks for Terraform formatting, validation, and tflint (deeper syntax/best-practice lint using [../../.tflint.hcl](../../.tflint.hcl)), Checkov Terraform policy checks, and Hadolint for Dockerfiles.
5. Python linting, formatting, and type checking using the shared settings in [../../quality/python/pyproject.toml](../../quality/python/pyproject.toml).

## Troubleshooting

### Gitleaks flags a false positive

Review the matched content first. If it is a safe test value, either rename the fixture to avoid secret-like patterns or use a documented local skip for that one commit:

```bash
SKIP=gitleaks git commit -m "documented false positive"
```

Do not make skipping the default workflow. CI still runs the shared secret-detection policy.

### Terraform hook says Terraform is not in `PATH`

Install Terraform locally and verify the command resolves before re-running pre-commit:

```bash
terraform version
pre-commit run terraform_fmt --all-files
```

If you work on Windows, prefer WSL2 if that is where your Terraform binary and provider credentials already live.

### tflint reports findings that Checkov/CI don't

tflint checks Terraform language issues (unused declarations, deprecated syntax, unconverted `variable` types) that are
separate from Checkov's security/policy rules. Fix the flagged file or adjust the ruleset in
[../../.tflint.hcl](../../.tflint.hcl) — do not disable the hook to work around a real finding.

### Hadolint fails while pulling or starting its Docker image

The Hadolint hook depends on a working Docker engine. Verify Docker is running, pull permissions are available, and then retry:

```bash
docker info
pre-commit run hadolint --all-files
```

If your environment cannot run Docker locally, keep the hook in CI and document the local limitation for your team.
