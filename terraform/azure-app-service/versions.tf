# ============================================================
# TEMPLATE: Terraform — Azure App Service
# WHEN TO USE: Deploying web apps without Kubernetes
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-app-service/
# MATURITY: Stable
# LAYOUT: versions.tf (providers), app-service.tf (plan/app/slot),
#         monitoring.tf (App Insights), locals.tf (tags)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.2.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "appservice.terraform.tfstate"
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
