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

## Repo Alignment

- Use existing cloud targets such as terraform/aws-eks, terraform/azure-aks, terraform/gcp-gke as references.
- Keep bootstrap and testing concerns isolated in terraform/_bootstrap and terraform/_testing.
- Align deployment automation with cd/targets and ci templates.
