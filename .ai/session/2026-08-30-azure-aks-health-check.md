# Azure AKS Terraform Health Check

- Added `node_provisioning_profile` with `mode = "Manual"` to retain the existing AKS managed node-pool model required by AzureRM v5.2.0.
- Updated the PostgreSQL private DNS virtual network link to use `private_dns_zone_id` and removed obsolete name/resource-group arguments.
- Verified with `terraform -chdir=terraform/azure-aks fmt -check -recursive` and `terraform -chdir=terraform/azure-aks validate`.
