# ============================================================
# TEMPLATE: Terraform — Azure App Service
# WHEN TO USE: Deploying web apps without Kubernetes
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-app-service/
# MATURITY: Stable
# ============================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    azurerm = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/azurerm"
      version = "~> 4.70.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "appservice.terraform.tfstate"
  # }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "azurerm" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  features {}
}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location = var.location

  tags = local.common_tags
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# App Service Plan
# ---------------------------------------------
resource "azurerm_service_plan" "main" {
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name                = "asp-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location            = azurerm_resource_group.main.location
  os_type             = var.os_type
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  sku_name            = var.sku_name

  tags = local.common_tags
# Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# App Service (Linux Web App)
# ---------------------------------------------
resource "azurerm_linux_web_app" "main" {
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name                = "app-${var.project}-${var.environment}" # <-- CHANGE THIS: must be globally unique
  resource_group_name = azurerm_resource_group.main.name
  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  # Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  https_only          = true

  site_config {
    # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    always_on = var.sku_name != "F1" # Free tier doesn't support always_on

    # Configure the runtime stack — uncomment ONE of the following:
    application_stack {
      # dotnet_version = "8.0"        # <-- CHANGE THIS: .NET 8
      # node_version   = "20-lts"     # <-- CHANGE THIS: Node.js 20
      # python_version = "3.12"       # <-- CHANGE THIS: Python 3.12
      # java_version   = "17"         # <-- CHANGE THIS: Java 17
      # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      docker_image_name        = "${var.docker_image}:latest" # <-- CHANGE THIS: or use a specific tag
      docker_registry_url      = var.docker_registry_url
      # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }

    health_check_path = "/health" # <-- CHANGE THIS: your health endpoint
  # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  app_settings = {
    # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ASPNETCORE_ENVIRONMENT"              = var.environment == "prod" ? "Production" : "Development" # <-- CHANGE THIS: for non-.NET apps
  # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  identity {
    # Note 24: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
    type = "SystemAssigned"
  }

  # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = local.common_tags
}

# ---------------------------------------------
# Staging Slot (for zero-downtime deployments)
# ---------------------------------------------
# Note 26: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  app_service_id = azurerm_linux_web_app.main.id
  https_only     = true

  # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  site_config {
    always_on         = var.sku_name != "F1"
    # Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    health_check_path = "/health"

    application_stack {
      # Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      docker_image_name        = "${var.docker_image}:latest"
      docker_registry_url      = var.docker_registry_url
      # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "ASPNETCORE_ENVIRONMENT"              = "Staging"
  }

  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = local.common_tags
}

# ---------------------------------------------
# Application Insights (optional but recommended)
# ---------------------------------------------
# Note 36: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project}-${var.environment}"
  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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
