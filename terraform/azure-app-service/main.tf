# ============================================================
# TEMPLATE: Terraform — Azure App Service
# WHEN TO USE: Deploying web apps without Kubernetes
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-app-service/
# MATURITY: Stable
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0" # <-- CHANGE THIS: pin to latest stable
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

# ---------------------------------------------
# App Service Plan
# ---------------------------------------------
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = local.common_tags
}

# ---------------------------------------------
# App Service (Linux Web App)
# ---------------------------------------------
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project}-${var.environment}" # <-- CHANGE THIS: must be globally unique
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    always_on = var.sku_name != "F1" # Free tier doesn't support always_on

    # Configure the runtime stack — uncomment ONE of the following:
    application_stack {
      # dotnet_version = "8.0"        # <-- CHANGE THIS: .NET 8
      # node_version   = "20-lts"     # <-- CHANGE THIS: Node.js 20
      # python_version = "3.12"       # <-- CHANGE THIS: Python 3.12
      # java_version   = "17"         # <-- CHANGE THIS: Java 17
      docker_image_name        = "${var.docker_image}:latest" # <-- CHANGE THIS: or use a specific tag
      docker_registry_url      = var.docker_registry_url
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    }

    health_check_path = "/health" # <-- CHANGE THIS: your health endpoint
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ASPNETCORE_ENVIRONMENT"              = var.environment == "prod" ? "Production" : "Development" # <-- CHANGE THIS: for non-.NET apps
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# ---------------------------------------------
# Staging Slot (for zero-downtime deployments)
# ---------------------------------------------
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id
  https_only     = true

  site_config {
    always_on         = var.sku_name != "F1"
    health_check_path = "/health"

    application_stack {
      docker_image_name        = "${var.docker_image}:latest"
      docker_registry_url      = var.docker_registry_url
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ASPNETCORE_ENVIRONMENT"              = "Staging"
  }

  tags = local.common_tags
}

# ---------------------------------------------
# Application Insights (optional but recommended)
# ---------------------------------------------
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"

  tags = local.common_tags
}

# ---------------------------------------------
# Common Tags
# ---------------------------------------------
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
