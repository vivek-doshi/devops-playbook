# Terraform Rules

Rules for Terraform under terraform/, backup/terraform/, and related CI/CD workflows.

## Required Practices

- Pin required_version and provider versions.
- Use remote state with locking for non-local workflows.
- Use variables and tfvars per environment; never hardcode environment values.
- Structure modules for reuse; keep root modules thin and explicit.
- Tag all resources consistently for ownership, environment, and cost allocation.
- Run fmt, validate, and plan in CI before apply.
- Include cost checks for infra-impacting pull requests where Infracost templates are available.

## State And Safety

- Never commit state files or plan outputs containing sensitive data.
- Use separate state per environment and workload boundary.
- Require review of plan output before apply in shared environments.
- Prefer least-privilege credentials and short-lived identity federation for pipeline auth.

## Module Design

- Inputs must be explicit with descriptions and sensible defaults.
- Outputs should expose stable integration points, not internal details.
- Keep modules cloud-targeted when needed, but naming and variable conventions consistent.

## Orchestrator Pattern (all `terraform/<target>/` stacks)

Every cloud target under `terraform/` (`aws-ecs`, `aws-eks`, `aws-lambda`, `azure-aks`,
`azure-app-service`, `gcp-gke`) follows the same layout:

- `terraform/<target>/main.tf` is an **orchestrator only** — it contains `module` blocks and
  nothing else. No `resource` blocks belong in this file.
- Each logical component (network, IAM, registry, compute/cluster, security groups, monitoring,
  autoscaling, backup/DR, etc.) lives in its own local module under
  `terraform/<target>/modules/<component>/` with its own `main.tf` (resources),
  `variables.tf` (inputs), and `outputs.tf` (values exposed to the orchestrator).
- Every module call in the orchestrator is gated by an `enable_<component>` boolean variable
  declared in the root `variables.tf`, using `count = var.enable_<component> ? 1 : 0`. This is how
  features are selected/deselected — flip the variable, don't edit the orchestrator.
- Core dependencies (typically `network`, `iam`) default to `true` because other modules consume
  their outputs; genuinely optional add-ons (GPU node pools, autoscaling, staging slots, backup/DR,
  monitoring) may default to `true` or `false` depending on whether most users need them day one.
- Cross-module references always go through `try(module.<name>[0].<output>, <fallback>)` so
  disabling a dependency doesn't break `terraform validate`/`plan` on the modules that remain
  enabled.
- Root-level `versions.tf` keeps only the `terraform {}`/`provider {}` blocks plus any single
  mandatory scaffold resource that every module depends on (e.g. the resource group in
  `azure-aks`/`azure-app-service`, the `google_project_service.apis` in `gcp-gke`). Root
  `locals.tf` keeps shared tags/labels. Root `outputs.tf` reads from modules via `try()`.

## Repo Alignment

- Use existing cloud targets such as terraform/aws-eks, terraform/azure-aks, terraform/gcp-gke as references.
- Keep bootstrap and testing concerns isolated in terraform/_bootstrap and terraform/_testing.
- Align deployment automation with cd/targets and ci templates.
