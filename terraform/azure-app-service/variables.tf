# ============================================================
# TEMPLATE: Terraform Variables — Azure App Service
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  # Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "myapp" # <-- CHANGE THIS
# Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "environment" {
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "dev" # <-- CHANGE THIS
}

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "location" {
  description = "Azure region for all resources"
  # Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "australiaeast" # <-- CHANGE THIS
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "os_type" {
  # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "OS type for the App Service Plan (Linux or Windows)"
  type        = string
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "Linux"
}

# Note 11: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "sku_name" {
  description = "SKU for the App Service Plan — see https://azure.microsoft.com/en-us/pricing/details/app-service/"
  # Note 12: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "P1v3" # <-- CHANGE THIS: B1 for dev, P1v3+ for production
# Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "docker_image" {
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Docker image name (without tag)"
  type        = string
  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "myapp" # <-- CHANGE THIS
}

# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
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
