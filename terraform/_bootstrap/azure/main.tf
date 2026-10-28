# ============================================================
# TEMPLATE: Terraform — Azure Remote State Bootstrap
# WHEN TO USE: Creating the shared Azure Blob backend before other Azure Terraform modules adopt remote state
# PREREQUISITES: Azure subscription, Azure CLI authenticated, local state for the first bootstrap apply
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: terraform/azure-aks/main.tf, terraform/azure-app-service/main.tf
# SUPPORT: template
# MATURITY: Template
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0" # <-- CHANGE THIS: pin to latest stable
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
resource "azurerm_resource_group" "terraform_state" {
  name     = local.resource_group_name
  location = local.location

  tags = local.common_tags
}

# ---------------------------------------------
# Storage Account
# ---------------------------------------------
resource "azurerm_storage_account" "terraform_state" {
  name                            = local.storage_account_name # <-- CHANGE THIS: storage account names must be globally unique and lowercase
  resource_group_name             = azurerm_resource_group.terraform_state.name
  location                        = azurerm_resource_group.terraform_state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 90
    }

    container_delete_retention_policy {
      days = 90
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------
# Blob Container
# ---------------------------------------------
resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "resource_group_name" {
  description = "Azure resource group name to copy into backend \"azurerm\" resource_group_name settings in the other Terraform modules."
  value       = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = "Azure storage account name to copy into backend \"azurerm\" storage_account_name settings in the other Terraform modules."
  value       = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = "Blob container name to copy into backend \"azurerm\" container_name settings in the other Terraform modules."
  value       = azurerm_storage_container.terraform_state.name
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  project              = "devops-playbook" # <-- CHANGE THIS: replace with your organisation or platform project name
  environment          = "shared"
  location             = "westeurope"        # <-- CHANGE THIS: choose the Azure region that will host shared Terraform state
  resource_group_name  = "rg-tfstate-shared" # <-- CHANGE THIS: align with your Azure naming standard
  storage_account_name = "tfstateshared001"  # <-- CHANGE THIS: must be globally unique, lowercase, and 3-24 characters

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "terraform-state"
  }
}
