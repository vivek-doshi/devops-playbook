# ============================================================
# TEMPLATE: Terraform Variables — Azure AKS
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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_subnet_prefix" {
  description = "Subnet address prefix for the AKS nodes"
  type        = string
  default     = "10.1.0.0/20"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS — run `az aks get-versions -l <region>` to see available versions"
  type        = string
  default     = "1.29" # <-- CHANGE THIS: use latest stable
}

variable "node_count" {
  description = "Number of nodes in the default node pool (ignored if autoscaling is enabled)"
  type        = number
  default     = 3
}

variable "node_vm_size" {
  description = "VM size for AKS nodes — see https://learn.microsoft.com/en-us/azure/virtual-machines/sizes"
  type        = string
  default     = "Standard_D4s_v5" # <-- CHANGE THIS: size to your workload
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaler on the default node pool"
  type        = bool
  default     = true
}

variable "node_min_count" {
  description = "Minimum node count when autoscaling is enabled"
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum node count when autoscaling is enabled"
  type        = number
  default     = 10
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry (Basic, Standard, Premium)"
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

# ---------------------------------------------
# Feature toggles — used only by the orchestrator (main.tf) to select
# which modules to run. Disabling "network" breaks dependent modules
# unless you also disable everything that depends on it.
# ---------------------------------------------
variable "enable_network" {
  description = "Provision the VNet and AKS subnet (core dependency for other modules)"
  type        = bool
  default     = true
}

variable "enable_acr" {
  description = "Provision the Azure Container Registry"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Provision the Log Analytics workspace for Container Insights"
  type        = bool
  default     = true
}

variable "enable_aks" {
  description = "Provision the AKS cluster and node pools"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Provision the PostgreSQL Flexible Server backup/DR stack (modules/backup)"
  type        = bool
  default     = false
}

# ---------------------------------------------
# Backup / DR (modules/backup) — only used when enable_backup = true
# ---------------------------------------------
variable "db_admin_username" {
  description = "PostgreSQL administrator login"
  type        = string
  default     = "dbadmin" # <-- CHANGE THIS
}

variable "db_sku" {
  description = "Flexible Server SKU (tier_name)"
  type        = string
  default     = "GP_Standard_D2s_v3" # <-- CHANGE THIS: B for dev, GP for prod
}

variable "db_storage_mb" {
  type    = number
  default = 32768 # 32 GB  # <-- CHANGE THIS
}

variable "db_version" {
  type    = string
  default = "16" # <-- CHANGE THIS
}

variable "backup_retention_days" {
  description = "Backup retention period in days (7-35)"
  type        = number
  default     = 14 # <-- CHANGE THIS
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup (required for cross-region restore)"
  type        = bool
  default     = true # always true in production
}

variable "dr_location" {
  description = "Secondary Azure region for the geo-replica"
  type        = string
  default     = "westus2" # <-- CHANGE THIS
}

variable "key_vault_id" {
  description = "Optional Key Vault resource ID for storing the generated database password"
  type        = string
  default     = null
  nullable    = true
}

variable "alert_action_group_id" {
  description = "Azure Monitor action group ID for backup failure alerts"
  type        = string
  default     = "" # <-- CHANGE THIS
}
