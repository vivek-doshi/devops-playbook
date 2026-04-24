---
agent: agent
model: claude-sonnet-4-6
tools: ['codebase', 'editFiles', 'search']
description: 'Generate Terraform bootstrap modules that provision remote state storage before any other Terraform can run.'
---

# Terraform Remote State Bootstrap Generator

You are a senior infrastructure engineer. Generate the "bootstrap" Terraform configurations that must be run once, manually, before any other Terraform in this repo can function. This solves the chicken-and-egg problem of remote state.

## Context

Read these files first:
- All files in `terraform/` — understand the structure and conventions used
- `terraform/README.md` — understand the existing conventions (naming, tagging, `# <-- CHANGE THIS` markers)
- `docs/guides/secrets-management.md` — understand how secrets are handled

## The problem you are solving

Every `terraform/*/main.tf` has a commented-out backend block. Before teams can uncomment it, the backend storage must exist. This bootstrap module creates that storage using local state, then teams migrate to remote state.

## Your deliverables

### 1. `terraform/_bootstrap/aws/main.tf`

A Terraform configuration that provisions:
- S3 bucket for state storage with:
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked on all four settings
  - Lifecycle rule to delete old versions after 90 days
  - A `# <-- CHANGE THIS` comment on the bucket name
- DynamoDB table for state locking with:
  - `LockID` as the hash key (string)
  - PAY_PER_REQUEST billing mode
  - Point-in-time recovery enabled
- IAM policy document (output only, not attached) showing the minimum permissions a CI role needs to use this backend
- All resources tagged with `Project`, `Environment = "shared"`, `ManagedBy = "terraform"`, `Purpose = "terraform-state"`

Include at the top of the file a large comment block explaining:
1. This runs ONCE with local state
2. After apply, uncomment the backend blocks in other modules
3. Never run `terraform destroy` on this module in production

### 2. `terraform/_bootstrap/azure/main.tf`

A Terraform configuration that provisions:
- Resource group for state storage
- Storage account with:
  - `Standard_LRS` replication
  - Minimum TLS 1.2 enforced
  - Blob versioning enabled
  - Soft delete for blobs (90 days) and containers (90 days)
  - Public network access disabled (teams access via Azure AD)
- Blob container named `tfstate`
- Outputs the `storage_account_name`, `container_name`, and `resource_group_name` needed for backend configuration

### 3. `terraform/_bootstrap/gcp/main.tf`

A Terraform configuration that provisions:
- GCS bucket for state storage with:
  - Versioning enabled
  - Uniform bucket-level access
  - 90-day lifecycle rule to delete non-current versions
  - `STANDARD` storage class
- Outputs the bucket name for backend configuration
- Enables the `storage.googleapis.com` API

### 4. `terraform/_bootstrap/README.md`

A step-by-step guide covering:
- When to run this (first time only, by a human with admin rights)
- The exact commands: `terraform init`, `terraform plan`, `terraform apply`
- How to migrate existing local state to the new backend: `terraform init -migrate-state`
- How to give CI/CD pipelines access (link to `docs/guides/github-actions-oidc.md`)
- A warning box explaining the consequences of accidentally destroying this module
- A table showing which backend config values to copy into each `terraform/*/main.tf`

### 5. Update `terraform/README.md`

Add a "Before you begin" section at the top (before "How to Use") pointing to `_bootstrap/README.md` and explaining that remote state must be configured first.

## Style rules

- Follow every naming and tagging convention already established in `terraform/azure-aks/main.tf`
- Use `~>` version constraints for providers, matching the versions already in use
- Every resource must have a comment explaining what it does and why the specific configuration was chosen
- Outputs must have descriptive `description` values — they will be copy-pasted into backend configs
- Do not use modules — keep bootstrap configs flat and simple so they are easy to audit