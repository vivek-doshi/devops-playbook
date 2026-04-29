# Conftest Policies

[Conftest](https://www.conftest.dev/) provides shift-left policy testing for Kubernetes manifests,
Helm charts, and Terraform plans using **Rego** (Open Policy Agent).
Violations are caught before `kubectl apply` or `terraform apply` — in the developer's
editor, in pre-commit hooks, and in CI pipelines.

---

## Directory structure

```
policy/conftest/
├── .conftest.yaml          # Default conftest configuration
├── kubernetes/             # Policies for Kubernetes manifests and Helm output
│   ├── deny_latest_tag.rego
│   ├── deny_privileged.rego
│   ├── require_labels.rego
│   ├── require_probes.rego
│   └── require_resources.rego
└── terraform/              # Policies for Terraform plan JSON
    └── deny_public_s3.rego
```

---

## Policy reference

| File | Kind | What it enforces |
|------|------|-----------------|
| `kubernetes/deny_latest_tag.rego` | Deployment, Pod | No `:latest` or untagged images |
| `kubernetes/require_resources.rego` | Deployment | CPU + memory requests **and** limits on every container |
| `kubernetes/require_probes.rego` | Deployment | `livenessProbe` + `readinessProbe` when `replicas > 1` |
| `kubernetes/deny_privileged.rego` | Deployment, Pod | No `privileged=true`, no `allowPrivilegeEscalation=true`, `runAsNonRoot=true` required |
| `kubernetes/require_labels.rego` | Deployment, Namespace | `app` + `version` labels on Deployments; `environment` ∈ `{dev,staging,production}` on Namespaces |
| `terraform/deny_public_s3.rego` | Terraform plan | `aws_s3_bucket` ACL must not be `public-read` or `public-read-write` |

---

## Prerequisites

```bash
# macOS / Linux via Homebrew
brew install conftest

# Or download a binary from https://github.com/open-policy-agent/conftest/releases
# and place it on your PATH.

# Verify
conftest --version
```

---

## Running policies locally

### Test raw Kubernetes manifests

```bash
# All policies against the shared base manifests
conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes

# A specific overlay
conftest test cd/kubernetes/_overlays/dev/ --policy policy/conftest/kubernetes

# A single file
conftest test cd/kubernetes/_base/deployment.yaml --policy policy/conftest/kubernetes
```

### Test rendered Helm output

Pipe `helm template` directly to conftest so you check the final rendered
YAML rather than the templates:

```bash
# Webapp chart with dev values
helm template webapp cd/helm/webapp \
  -f cd/helm/webapp/values.dev.yaml \
  | conftest test - --policy policy/conftest/kubernetes

# Webapp chart with prod values
helm template webapp cd/helm/webapp \
  -f cd/helm/webapp/values.prod.yaml \
  | conftest test - --policy policy/conftest/kubernetes
```

### Test Terraform plans

Conftest reads Terraform plan JSON, not HCL.  Generate the plan file first:

```bash
cd terraform/aws-eks
terraform init
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json

# Run the Terraform policies
conftest test plan.json --policy ../../policy/conftest/terraform
```

---

## Output formats

The default output is `table` (set in `.conftest.yaml`).  Override for CI:

```bash
# JUnit XML for GitHub Actions test-results upload
conftest test cd/kubernetes/_base/ \
  --policy policy/conftest/kubernetes \
  --output junit > results.xml

# JSON for downstream tooling
conftest test cd/kubernetes/_base/ \
  --policy policy/conftest/kubernetes \
  --output json
```

---

## Adding to CI

### GitHub Actions

```yaml
# .github/workflows/policy.yml  (add as a job or a step in your existing CI workflow)
- name: Install conftest
  run: |
    VERSION=$(curl -s https://api.github.com/repos/open-policy-agent/conftest/releases/latest \
      | jq -r .tag_name | tr -d v)
    curl -Lo conftest.tar.gz \
      "https://github.com/open-policy-agent/conftest/releases/download/v${VERSION}/conftest_${VERSION}_Linux_x86_64.tar.gz"
    tar xzf conftest.tar.gz
    sudo mv conftest /usr/local/bin/

- name: Policy check — Kubernetes base manifests
  run: conftest test cd/kubernetes/_base/ --policy policy/conftest/kubernetes

- name: Policy check — Helm (dev values)
  run: |
    helm template webapp cd/helm/webapp -f cd/helm/webapp/values.dev.yaml \
      | conftest test - --policy policy/conftest/kubernetes

- name: Policy check — Terraform plan (aws-eks)
  run: |
    cd terraform/aws-eks
    terraform init -backend=false
    terraform plan -out=plan.tfplan
    terraform show -json plan.tfplan > plan.json
    conftest test plan.json --policy ../../policy/conftest/terraform
```

### pre-commit hook

Add to `.pre-commit-config.yaml` to catch violations before every commit:

```yaml
- repo: https://github.com/open-policy-agent/conftest
  rev: v0.57.0   # pin to a specific release
  hooks:
    - id: conftest-test
      name: conftest — Kubernetes manifests
      files: ^cd/kubernetes/
      args: [--policy, policy/conftest/kubernetes]
```

---

## Relationship to Kyverno

| | Conftest | Kyverno |
|---|---|---|
| **When** | Pre-commit / CI (shift-left) | Kubernetes admission webhook (runtime) |
| **Input** | YAML files, Helm output, Terraform plan JSON | Live API objects |
| **Blocks deploy?** | No — fails the pipeline | Yes — rejects the `kubectl apply` |
| **Policy language** | Rego | Kyverno YAML DSL |

Use both: conftest catches issues early, Kyverno is the final safety net in the cluster.
See `policy/kyverno/` for the admission-time equivalents.
