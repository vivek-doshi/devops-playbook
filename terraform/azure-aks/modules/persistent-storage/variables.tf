# ============================================================
# TEMPLATE: Terraform Variables — Azure AKS Persistent Storage
# WHAT to CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "enable_persistent_storage" {
  description = "Enable persistent storage for AKS workloads"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to enable

  validation {
    condition     = can(var.enable_persistent_storage ? true : false)
    error_message = "enable_persistent_storage must be a boolean."
  }
}

variable "storage_type" {
  description = "Type of persistent storage to provision"
  type        = string
  default     = "disk" # <-- CHANGE THIS: disk, file-share, or blob-storage

  validation {
    condition     = contains(["disk", "file-share", "blob-storage"], var.storage_type)
    error_message = "storage_type must be one of: disk, file-share, or blob-storage."
  }
}

variable "storage_class_name" {
  description = "Name of the storage class (for Disk and File Share)"
  type        = string
  default     = "standard" # <-- CHANGE THIS: standard, premium, or ultra

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_class_name))
    error_message = "storage_class_name must contain only lowercase letters and numbers."
  }
}

variable "storage_size" {
  description = "Size of the Disk in GB (if using Disk)"
  type        = number
  default     = 100 # <-- CHANGE THIS: size to your workload

  validation {
    condition     = var.storage_size > 0
    error_message = "storage_size must be greater than 0."
  }
}

variable "storage_sku" {
  description = "SKU for Azure Disk (if using Disk)"
  type        = string
  default     = "Standard_LRSs" # <-- CHANGE THIS: Standard_LRSs, Standard_GRSs, Standard_RRSs

  validation {
    condition     = contains(["Standard_LRSs", "Standard_GRSs", "Standard_RRSs"], var.storage_sku)
    error_message = "storage_sku must be one of: Standard_LRSs, Standard_GRSs, or Standard_RRSs."
  }
}

variable "storage_zone" {
  description = "Availability zone for the Disk (if using Disk)"
  type        = string
  default     = "1" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[0-9]+$", var.storage_zone))
    error_message = "storage_zone must contain only numbers."
  }
}

variable "storage_resource_group_name" {
  description = "Resource group name for storage resources (if using Disk or File Share)"
  type        = string
  default     = "default" # <-- CHANGE THIS: match your resource group

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_resource_group_name))
    error_message = "storage_resource_group_name must contain only lowercase letters and numbers."
  }
}

variable "storage_location" {
  description = "Location for storage resources (if using Disk or File Share)"
  type        = string
  default     = "eastus" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.storage_location))
    error_message = "storage_location must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "storage_access_tier" {
  description = "Access tier for File Share (if using File Share)"
  type        = string
  default     = "TransactionOptimized" # <-- CHANGE THIS: TransactionOptimized, Hot, Cool

  validation {
    condition     = contains(["TransactionOptimized", "Hot", "Cool"], var.storage_access_tier)
    error_message = "storage_access_tier must be one of: TransactionOptimized, Hot, or Cool."
  }
}

variable "storage_enable_https" {
  description = "Enable HTTPS for File Share (if using File Share)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_enable_https ? true : false)
    error_message = "storage_enable_https must be a boolean."
  }
}

variable "storage_network_acl" {
  description = "Enable network ACL for File Share (if using File Share)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_network_acl ? true : false)
    error_message = "storage_network_acl must be a boolean."
  }
}

variable "storage_force_destroy" {
  description = "Force destroy Blob Storage container on deletion (if using Blob Storage)"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to force destroy

  validation {
    condition     = can(var.storage_force_destroy ? true : false)
    error_message = "storage_force_destroy must be a boolean."
  }
}

variable "storage_labels" {
  description = "Additional labels to apply to storage resources"
  type        = map(string)
  default = {
    workload = "aks"
    environment = var.environment
  }
}
