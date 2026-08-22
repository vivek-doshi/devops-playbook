# ============================================================
# TEMPLATE: Terraform Variables — Azure App Service
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "myapp" # <-- CHANGE THIS

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project must be a non-empty string."
  }
}

variable "cost_center" {
  description = "FinOps cost center tag applied to all resources"
  type        = string
  default     = "engineering-shared" # <-- CHANGE THIS

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "CostCenter must be a non-empty string."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "FinOps owner tag applied to all resources; must be an email address"
  type        = string
  default     = "platform@example.com" # <-- CHANGE THIS

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner))
    error_message = "Owner must be a valid email address."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "australiaeast" # <-- CHANGE THIS
}

variable "os_type" {
  description = "OS type for the App Service Plan (Linux or Windows)"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "SKU for the App Service Plan — see https://azure.microsoft.com/en-us/pricing/details/app-service/"
  type        = string
  default     = "P1v3" # <-- CHANGE THIS: B1 for dev, P1v3+ for production
}

variable "docker_image" {
  description = "Docker image name (without tag)"
  type        = string
  default     = "myapp" # <-- CHANGE THIS
}

variable "docker_registry_url" {
  description = "Docker registry URL (e.g., https://myacr.azurecr.io)"
  type        = string
  default     = "" # <-- CHANGE THIS
}

variable "docker_registry_username" {
  description = "Docker registry username (leave empty if using managed identity)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_registry_password" {
  description = "Docker registry password (leave empty if using managed identity)"
  type        = string
  default     = ""
  sensitive   = true
}

# ---------------------------------------------
# Feature toggles — used only by the orchestrator (main.tf) to select
# which modules to run. Disabling "app_service_plan" breaks the web_app
# module unless you also disable it.
# ---------------------------------------------
variable "enable_app_service_plan" {
  description = "Provision the App Service Plan (core dependency for the web_app module)"
  type        = bool
  default     = true
}

variable "enable_web_app" {
  description = "Provision the App Service (Linux Web App)"
  type        = bool
  default     = true
}

variable "enable_staging_slot" {
  description = "Provision a staging deployment slot for zero-downtime deployments"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Provision Application Insights"
  type        = bool
  default     = true
}
