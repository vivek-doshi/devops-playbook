# ============================================================
# TEMPLATE: Terraform Variables — Azure App Service
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "myapp" # <-- CHANGE THIS
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS
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
