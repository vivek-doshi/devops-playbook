# Terraform

This folder contains infrastructure blueprints for supported cloud deployment targets.

## Purpose

Use `terraform/` to provision repeatable infrastructure foundations for application delivery.

## What's Inside

- `azure-aks/`, `aws-eks/`, `gcp-gke/`: Kubernetes platforms.
- `azure-app-service/`, `aws-ecs/`, `aws-lambda/`: non-Kubernetes targets.
- `_bootstrap/`: backend/state bootstrapping guidance.
- `tests/`: validation support files.

## Use This Component Alone

- Provision one environment for one cloud target.
- Establish remote state and baseline IAM/network resources.

## Use This Component With Others

- With `cd/targets/`: deploy workloads onto provisioned infrastructure.
- With `ci/`: run plan/apply in controlled automation.
- With `finops/`: track cost impact and commitment strategy.
- With `backup/`: apply backup and recovery controls to provisioned services.

## Typical Workflow

1. Start with `_bootstrap/` and configure remote state.
2. Select target module and set variables.
3. Run `terraform init`, `terraform plan`, and `terraform apply`.
4. Integrate into CI and deployment workflows.
