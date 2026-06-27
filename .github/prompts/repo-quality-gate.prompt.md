---
mode: agent
model: claude-sonnet-4-6
tools:
  - read_file
  - create_file
  - run_terminal_command
description: >
  Generate a self-validating CI quality gate for the devops-playbook repo itself.
  The playbook ships quality gates for consumers; this gate validates the playbook's
  own assets — workflows, manifests, Helm charts, Terraform, Markdown links,
  catalog, and website build — before any PR merges.
---

# Prompt: Repo-Quality CI Gate

## TEMPLATE

You are acting as the platform engineer responsible for the devops-playbook repository's own
CI pipeline. Your task is to produce a complete, working GitHub Actions workflow at
`.github/workflows/repo-quality.yml` plus all supporting lint configuration files.

The gate must validate the playbook's own content — not consumer applications.
Every check must run in parallel jobs where possible. The gate must be fast (< 8 min total).

---

## WHEN TO USE

Invoke this prompt when:
- The `.github/workflows/repo-quality.yml` file does not exist or is incomplete
- Adding a new content domain (new Helm chart directory, new Terraform module, new golden path)
  that needs a corresponding lint job
- Upgrading a linting tool version (actionlint, kubeconform, yamllint, etc.)
- A PR introduces a Markdown link regression and there is no automated check blocking it

---

## PREREQUISITES

Before generating any file, confirm each tool is available as a GitHub-hosted runner binary
or installable via a pinned action. Do not require a Docker image pull for checks that can
run natively. Confirm the following paths exist in the repo before scoping the check:

| Check | Scope | Config file |
|---|---|---|
| markdown link check | `docs/**/*.md`, `README.md`, `GETTING_STARTED.md` | `.mlc-config.json` |
| actionlint | `.github/workflows/**/*.yml` | inline |
| yamllint | all `.yml`/`.yaml` except `docs/diagrams/` | `.yamllint.yml` |
| kubeconform | `cd/kubernetes/**/*.yaml` | inline (k8s 1.29) |
| helm lint + template | `cd/helm/*/` | inline per chart |
| terraform fmt + validate | `terraform/*/` (skip `_bootstrap`) | inline |
| conftest | `cd/kubernetes/_base/` against `policy/conftest/kubernetes` | inline |
| catalog validate | `catalog/` | `catalog/scripts/validate-catalog.py` |
| website/handbook build | `website/` or `handbook.html` if present | inline |

---

## MATURITY

**Stable** — required for all PRs to `main`. No maturity exceptions.

---

## GENERATION INSTRUCTIONS

### Step 1 — Scaffold the workflow skeleton

Create `.github/workflows/repo-quality.yml` with:

```
name: Repo Quality Gate

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: repo-quality-${{ github.ref }}
  cancel-in-progress: true
```

Add a top-level `jobs:` block. Each check below is a separate parallel job unless
a data dependency requires sequencing (catalog validate depends on yamllint).

### Step 2 — Markdown link checker job

Job name: `markdown-links`

Use `lychee-action` (pinned to SHA). Configure `.mlc-config.json` at repo root:

```json
{
  "ignorePatterns": [
    { "pattern": "localhost" },
    { "pattern": "example\\.com" },
    { "pattern": "YOUR-ORG" },
    { "pattern": "your-org" },
    { "pattern": "my-app" },
    { "pattern": "my-service" },
    { "pattern": "grafana\\.internal\\.company\\.com" }
  ],
  "timeout": "20s",
  "maxRetries": 3,
  "retryWaitTime": "2s",
  "excludeAllPrivate": true
}
```

Run against: `docs/**/*.md README.md GETTING_STARTED.md`

Fail on broken external links. Warn only on patterns matching the ignore list above.

### Step 3 — actionlint job

Job name: `actionlint`

Install via: `brew install actionlint` on `ubuntu-latest` using the installer script from
`https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash`
pinned to a specific version tag (set `ACTIONLINT_VERSION: 1.7.3` as env var).

Run: `./actionlint -color`

### Step 4 — yamllint job

Job name: `yamllint`

Generate `.yamllint.yml`:

```yaml
extends: default
rules:
  line-length:
    max: 140
    level: warning
  truthy:
    allowed-values: ['true', 'false', 'on', 'off', 'yes', 'no']
    check-keys: false
  comments:
    min-spaces-from-content: 1
  braces:
    max-spaces-inside: 1
  brackets:
    max-spaces-inside: 1
ignore: |
  docs/diagrams/
  .devcontainer/
  node_modules/
  .git/
```

Run: `yamllint -c .yamllint.yml .`

### Step 5 — kubeconform job

Job name: `kubeconform`

Install kubeconform from GitHub releases, pinned version `0.6.7`.

Run against `cd/kubernetes/` with:
- `--strict`
- `--kubernetes-version 1.29.0`
- `--ignore-missing-schemas` (for CRDs like ExternalSecret, Kyverno ClusterPolicy)
- `--summary`
- Output format: `pretty`

Skip files matching `*_test.yaml` and `kustomization.yaml`.

### Step 6 — Helm lint + template job

Job name: `helm-lint`

For each chart directory found under `cd/helm/*/`:
1. Run `helm lint <chart-dir>` with `--strict`
2. Run `helm template <chart-name> <chart-dir>` and pipe output through kubeconform
   with the same flags as Step 5

Fail the job if any chart fails lint or produces manifests that fail kubeconform.

Use a bash loop to discover charts dynamically so new charts are automatically included:

```bash
for chart in cd/helm/*/; do
  helm lint "$chart" --strict
  helm template "$(basename $chart)" "$chart" | \
    kubeconform --strict --kubernetes-version 1.29.0 --ignore-missing-schemas -
done
```

### Step 7 — Terraform fmt + validate job

Job name: `terraform`

Matrix over cloud modules: `[aws-eks, azure-aks, gcp-gke, aws-lambda, aws-ecs, azure-app-service]`

Steps per matrix entry:
1. `terraform init -backend=false`
2. `terraform fmt -check -recursive`
3. `terraform validate`

Skip `terraform/_bootstrap/` (requires live cloud credentials).
Use `hashicorp/setup-terraform@v3` pinned to a SHA.

### Step 8 — Conftest / OPA job

Job name: `conftest`

Run: `conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes --output table`

Also run against the Helm chart rendered output from Step 6:

```bash
helm template webapp cd/helm/webapp/ | conftest test - --policy policy/conftest/kubernetes
```

Fail on any policy violation. Warn on `warn` level rules only.

### Step 9 — Catalog validation job

Job name: `catalog-validate`

Run:
```bash
pip install pyyaml --quiet
python catalog/scripts/validate-catalog.py --strict --skip-url-check
```

Needs: `python 3.12`, `actions/setup-python@v5`

### Step 10 — Website / handbook build job (conditional)

Job name: `handbook-build`

If `website/` directory exists: run the build command appropriate to the stack
(e.g., `npm run build` after `npm ci`).

If `handbook.html` exists at repo root or `docs/`: run an HTML validation check
using `vnu-jar` or a lightweight validator.

Skip gracefully (exit 0) if neither path is present, but log a warning.

### Step 11 — Status summary job

Job name: `quality-gate`

Add a final job that depends on all prior jobs via `needs:` array. This is the single
required status check registered in branch protection. If all upstream jobs pass, this
job passes. GitHub branch protection only needs to require this single job name.

```yaml
quality-gate:
  name: "✅ Repo Quality Gate"
  needs:
    - markdown-links
    - actionlint
    - yamllint
    - kubeconform
    - helm-lint
    - terraform
    - conftest
    - catalog-validate
    - handbook-build
  runs-on: ubuntu-latest
  if: always()
  steps:
    - name: Check all jobs passed
      run: |
        results='${{ toJSON(needs) }}'
        if echo "$results" | grep -q '"result":"failure"'; then
          echo "❌ One or more quality gate checks failed."
          exit 1
        fi
        echo "✅ All quality gate checks passed."
```

---

## OUTPUT CHECKLIST

Confirm before finishing:

- [ ] `.github/workflows/repo-quality.yml` created with all 10 parallel jobs + status summary
- [ ] `.mlc-config.json` created with ignore patterns for placeholder URLs
- [ ] `.yamllint.yml` created with sensible defaults and `docs/diagrams/` excluded
- [ ] All tool versions pinned (not `latest`) with version constants as env vars
- [ ] Matrix job for Terraform covers all non-bootstrap modules
- [ ] `quality-gate` summary job uses `if: always()` so it reports failure even when upstream jobs are skipped
- [ ] Branch protection instruction comment added at top of workflow file
- [ ] `README.md` updated with a "Repo CI" badge pointing to this workflow
- [ ] No new secrets required — all checks run without cloud credentials

---

## CROSS-REFERENCES

- Existing CI templates this gate complements: `ci/github-actions/`
- Kyverno policies under test: `policy/kyverno/`
- Conftest policies: `policy/conftest/kubernetes`
- Catalog scripts: `catalog/scripts/`
- ADR for folder structure: `docs/decisions/ADR-001-folder-structure.md`
- Related golden path: `docs/golden-paths/supply-chain-security.md`
