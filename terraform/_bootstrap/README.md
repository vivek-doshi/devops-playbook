# Terraform Remote State Bootstrap

Run these bootstrap modules once, by a human with administrative access, before you use any of the other Terraform folders in this repository. The goal is to create the shared backend storage while Terraform is still using local state, then migrate every workload module to that remote backend.

> Warning
> Destroying these bootstrap resources later will break every Terraform module that depends on the backend. State reads, plans, applies, and drift recovery will all fail until the backend is restored or state is manually recovered.

## When to Run This

Run the appropriate bootstrap folder the first time you adopt this repository for AWS, Azure, or GCP. Do not run it from CI first. The bootstrap step needs privileged access to create the storage that CI will use afterwards.

## Commands

AWS example:

```bash
cd terraform/_bootstrap/aws
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Azure example:

```bash
cd terraform/_bootstrap/azure
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

GCP example:

```bash
cd terraform/_bootstrap/gcp
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Migrate Existing Local State

After the bootstrap apply succeeds, copy the backend values into the relevant `terraform/*/main.tf` backend block, uncomment it, and migrate state:

```bash
terraform init -migrate-state
```

Terraform will prompt before moving local state into the remote backend. Review the destination carefully before accepting.

## CI/CD Access

Use workload identity or OIDC rather than long-lived static credentials when you grant pipelines access to the backend. The repository guide at [docs/guides/github-actions-oidc.md](../../docs/guides/github-actions-oidc.md) is the right starting point for GitHub Actions.

For AWS, the bootstrap module outputs a minimum IAM policy document you can attach to a CI role after you create that role through your normal identity process.

## Backend Values to Copy

| Cloud | Bootstrap folder | Backend block | Values to copy into other modules |
|---|---|---|---|
| AWS | `terraform/_bootstrap/aws/` | `backend "s3"` | `bucket = state_bucket_name`, `region = backend_region`, `dynamodb_table = lock_table_name`, plus a per-module `key` such as `eks/terraform.tfstate` |
| Azure | `terraform/_bootstrap/azure/` | `backend "azurerm"` | `resource_group_name = resource_group_name`, `storage_account_name = storage_account_name`, `container_name = container_name`, plus a per-module `key` such as `aks.terraform.tfstate` |
| GCP | `terraform/_bootstrap/gcp/` | `backend "gcs"` | `bucket = bucket_name`, plus a per-module `prefix` such as `gke/terraform.tfstate` |

## Suggested Order

1. Edit the `# <-- CHANGE THIS` values in the bootstrap module for your cloud.
2. Run `terraform init`, `terraform plan`, and `terraform apply` in the bootstrap folder.
3. Copy the resulting backend values into the workload module backend blocks.
4. Run `terraform init -migrate-state` inside each workload module.
5. Update CI identities to use the new remote backend.
