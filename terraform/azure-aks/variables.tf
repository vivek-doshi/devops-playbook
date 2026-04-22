# ============================================================
# TEMPLATE: Terraform Variables — Azure AKS
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "myapp" # <-- CHANGE THIS
}

variable "environment" {
  # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "location" {
  description = "Azure region for all resources"
  # Note 5: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "australiaeast" # <-- CHANGE THIS
}

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "10.1.0.0/16"
}

variable "aks_subnet_prefix" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Subnet address prefix for the AKS nodes"
  type        = string
  default     = "10.1.0.0/20"
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS — run `az aks get-versions -l <region>` to see available versions"
  # Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "1.29" # <-- CHANGE THIS: use latest stable
}

# Note 11: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "node_count" {
  description = "Number of nodes in the default node pool (ignored if autoscaling is enabled)"
  type        = number
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = 3
}

variable "node_vm_size" {
  # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "VM size for AKS nodes — see https://learn.microsoft.com/en-us/azure/virtual-machines/sizes"
  type        = string
  default     = "Standard_D4s_v5" # <-- CHANGE THIS: size to your workload
# Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaler on the default node pool"
  # Note 15: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = bool
  default     = true
}

# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "node_min_count" {
  description = "Minimum node count when autoscaling is enabled"
  type        = number
  # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = 2
}

variable "node_max_count" {
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Maximum node count when autoscaling is enabled"
  type        = number
  default     = 10
# Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
  # Note 20: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "Standard"
}
