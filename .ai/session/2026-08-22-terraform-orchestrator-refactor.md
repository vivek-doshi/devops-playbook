# Session: Terraform Orchestrator/Feature-Toggle Refactor + .ai Refresh

## Goal

1. Convert every `terraform/<target>/` stack from "several flat `.tf` files" into an
   orchestrator (`main.tf`) + local feature modules (`modules/<component>/`), so entire
   components can be turned on/off via boolean variables without touching `main.tf`.
2. Refresh `.ai/` content to describe the new structure.

## What changed

For all six targets — `aws-ecs`, `aws-eks`, `aws-lambda`, `azure-aks`, `azure-app-service`,
`gcp-gke` — every resource-bearing file (`network.tf`, `iam.tf`, `ecs.tf`/`eks.tf`/`aks.tf`/
`gke.tf`, `security-groups.tf`, `alb.tf`/`api-gateway.tf`, `autoscaling.tf`, `monitoring.tf`,
`backup.tf`, etc.) was moved into `terraform/<target>/modules/<component>/` as a proper local
module (`main.tf` + `variables.tf` + `outputs.tf`, plus `versions.tf` where a module needs a
provider alias, e.g. `aws-eks/modules/backup` for the DR region).

`terraform/<target>/main.tf` is now a pure orchestrator: only `module "<component>" { count =
var.enable_<component> ? 1 : 0 ... }` blocks, no resources. Root `variables.tf` gained
`enable_<component>` booleans per module (core dependencies like `network`/`iam` default
`true`; genuinely optional add-ons like `backup`, GPU node pools, staging slots default
based on whether most users need them day one). Root `outputs.tf` reads values via
`try(module.<name>[0].<output>, null)` so disabling a module doesn't break output evaluation.
Root `versions.tf` keeps only the `terraform {}`/`provider {}` blocks plus the one mandatory
scaffold resource everything depends on (resource group for Azure targets,
`google_project_service.apis` for GCP). Root `locals.tf` keeps shared tags/labels.

Cross-module dependencies are wired explicitly in the orchestrator (e.g. `aws-ecs`'s `ecs`
module receives `vpc/subnet ids` from `network`, `target_group_arn`/`listener_arn` from `alb`).
Where a real resource-level `depends_on` was needed across modules (e.g. ECS service must
wait for the ALB listener), the dependency is passed as a module input variable rather than
a literal `depends_on = [...]` on a resource in another module.

Verified with `terraform fmt -check -recursive` and `terraform init -backend=false &&
terraform validate` for all six modules — all pass.

## .ai content refreshed

- [.ai/instructions/terraform-rules.md](../instructions/terraform-rules.md): added an
  "Orchestrator Pattern" section documenting the `main.tf`-is-orchestrator-only convention,
  the `modules/<component>/` layout, and the `enable_<component>` toggle convention.
- [.ai/retrieval/search-hints.md](../retrieval/search-hints.md): updated the
  `terraform/**/main.tf` path hint to distinguish the orchestrator from
  `terraform/<target>/modules/**/main.tf` (actual resources).
- [.ai/context/repo_map.md](../context/repo_map.md): updated the terraform subtree to show
  `modules/` per target and annotated each `main.tf` as "(orchestrator: module calls only)".

## Follow-ups

- If a new cloud target is added, follow the same orchestrator + `modules/<component>/`
  pattern and add `enable_<component>` toggles rather than writing resources directly in
  `main.tf`.
- `terraform plan`/`apply` (with real credentials) has not been exercised for the toggle-off
  paths (`enable_x = false`) — CI only runs `fmt`/`validate`, which doesn't evaluate `count`
  against real state. If adopting these toggles in a live environment, test disabling each
  optional module once before relying on it.
