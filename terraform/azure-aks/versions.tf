# ============================================================
# TEMPLATE: Terraform — Azure Kubernetes Service (AKS)
# WHEN TO USE: Provisioning a production-ready AKS cluster on Azure
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-aks/, cd/kubernetes/
# MATURITY: Stable
# LAYOUT: versions.tf (providers), network.tf (VNet/subnet), acr.tf (registry),
#         aks.tf (cluster/node pools), monitoring.tf (Log Analytics),
#         backup.tf (DR/backup), locals.tf (tags)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.78.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "aks.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location

  tags = local.common_tags
}
