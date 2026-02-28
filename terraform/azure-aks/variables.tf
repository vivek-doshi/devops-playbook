# ============================================================
# TEMPLATE: Terraform Variables — Azure AKS
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
