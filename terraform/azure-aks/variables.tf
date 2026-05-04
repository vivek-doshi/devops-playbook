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

  validation {
    condition     = length(trim(var.project)) > 0
    error_message = "Project must be a non-empty string."
  }
}

variable "cost_center" {
  description = "FinOps cost center tag applied to all resources"
  type        = string
  default     = "engineering-shared" # <-- CHANGE THIS

  validation {
    condition     = length(trim(var.cost_center)) > 0
    error_message = "CostCenter must be a non-empty string."
  }
}

variable "environment" {
  # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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

variable "gpu_node_pool_enabled" {
  description = "Create a separate GPU-enabled user node pool for model training or inference workloads"
  type        = bool
  default     = false
}

variable "gpu_node_pool_name" {
  description = "Name of the AKS GPU node pool; must be 1-12 lowercase alphanumeric characters"
  type        = string
  default     = "gpu"

  validation {
    condition     = can(regex("^[a-z0-9]{1,12}$", var.gpu_node_pool_name))
    error_message = "gpu_node_pool_name must be 1-12 lowercase alphanumeric characters."
  }
}

variable "gpu_node_vm_size" {
  description = "VM size for the AKS GPU node pool"
  type        = string
  default     = "Standard_NC4as_T4_v3" # <-- CHANGE THIS: pick the GPU SKU that matches your workload and region
}

variable "gpu_enable_autoscaling" {
  description = "Enable cluster autoscaler on the GPU node pool"
  type        = bool
  default     = true
}

variable "gpu_node_count" {
  description = "Node count for the GPU node pool when autoscaling is disabled"
  type        = number
  default     = 1
}

variable "gpu_node_min_count" {
  description = "Minimum node count for the GPU node pool when autoscaling is enabled"
  type        = number
  default     = 0
}

variable "gpu_node_max_count" {
  description = "Maximum node count for the GPU node pool when autoscaling is enabled"
  type        = number
  default     = 3
}

variable "gpu_node_os_disk_size_gb" {
  description = "OS disk size in GiB for GPU nodes"
  type        = number
  default     = 256
}

variable "gpu_node_taint_enabled" {
  description = "Apply a NoSchedule taint to the GPU node pool so only explicit ML workloads land on it"
  type        = bool
  default     = true
}

variable "gpu_node_labels" {
  description = "Additional Kubernetes labels to apply to the GPU node pool"
  type        = map(string)
  default = {
    accelerator = "nvidia-gpu"
    workload    = "ml"
  }
}
