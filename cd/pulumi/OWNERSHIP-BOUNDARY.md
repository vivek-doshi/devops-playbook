# TEMPLATE: Pulumi Ownership Boundary
# WHEN TO USE: Defining Terraform and Pulumi resource ownership to prevent drift.
# PREREQUISITES: Review terraform/ target modules and platform architecture ADR decisions.
# MATURITY: Stable

## Decision

Terraform owns foundational infrastructure:
- network (VPC/VNet/subnets)
- cluster control planes (EKS/AKS/GKE)
- IAM and cloud identity baselines
- shared state/bootstrap resources

Pulumi owns application-layer cloud resources only:
- app deployments and app-specific service resources
- app ingress/routing objects where cloud-native objects are required
- app-specific messaging and integration resources

## Rule

Do not run Terraform and Pulumi against the same resource scope in the same environment.

## Week 3 Resolution

- Pulumi examples now include explicit remote backend configuration and environment stack files.
- Teams must either:
  1. keep Terraform as source of truth for infra and restrict Pulumi to app-layer resources, or
  2. migrate ownership intentionally with a one-time handoff plan before enabling Pulumi apply in that environment.

## Implementation Guidance

- If Terraform already manages cluster/network in an environment, keep Pulumi code for that scope as reference only.
- If adopting Pulumi for an app-layer stack, verify no overlapping Terraform state paths and no duplicated resource names.
- Add ownership notes in PR descriptions for every new cloud resource.
