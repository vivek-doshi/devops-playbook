# ============================================================
# TEMPLATE: Terraform Variables — GCP GKE Persistent Storage
# WHAT to CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "enable_persistent_storage" {
  description = "Enable persistent storage for GKE workloads"
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
  default     = "persistent-disk" # <-- CHANGE THIS: persistent-disk, cloud-storage, or memorystore

  validation {
    condition     = contains(["persistent-disk", "cloud-storage", "memorystore"], var.storage_type)
    error_message = "storage_type must be one of: persistent-disk, cloud-storage, or memorystore."
  }
}

variable "storage_class_name" {
  description = "Name of the storage class (for Persistent Disk)"
  type        = string
  default     = "standard" # <-- CHANGE THIS: standard, premium, or ultra

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_class_name))
    error_message = "storage_class_name must contain only lowercase letters and numbers."
  }
}

variable "storage_size" {
  description = "Size of the Persistent Disk in GB (if using Persistent Disk)"
  type        = number
  default     = 100 # <-- CHANGE THIS: size to your workload

  validation {
    condition     = var.storage_size > 0
    error_message = "storage_size must be greater than 0."
  }
}

variable "storage_disk_type" {
  description = "Disk type for Persistent Disk (if using Persistent Disk)"
  type        = string
  default     = "pd-balanced" # <-- CHANGE THIS: pd-balanced, pd-ssd, pd-hdd, or pd-ultra

  validation {
    condition     = contains(["pd-balanced", "pd-ssd", "pd-hdd", "pd-ultra"], var.storage_disk_type)
    error_message = "storage_disk_type must be one of: pd-balanced, pd-ssd, pd-hdd, or pd-ultra."
  }
}

variable "storage_zone" {
  description = "Zone for the Persistent Disk (if using Persistent Disk)"
  type        = string
  default     = "us-central1-a" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.storage_zone))
    error_message = "storage_zone must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "storage_location" {
  description = "Location for Cloud Storage bucket (if using Cloud Storage)"
  type        = string
  default     = "us-central1" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.storage_location))
    error_message = "storage_location must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "storage_tier" {
  description = "Tier for Memorystore cluster (if using Memorystore)"
  type        = string
  default     = "PREMIUM" # <-- CHANGE THIS: PREMIUM or STANDARD

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.storage_tier)
    error_message = "storage_tier must be one of: PREMIUM or STANDARD."
  }
}

variable "storage_node_count" {
  description = "Node count for Memorystore cluster (if using Memorystore)"
  type        = number
  default     = 3 # <-- CHANGE THIS: adjust for your workload

  validation {
    condition     = var.storage_node_count > 0
    error_message = "storage_node_count must be greater than 0."
  }
}

variable "storage_node_memory_gb" {
  description = "Memory per node in GB for Memorystore cluster (if using Memorystore)"
  type        = number
  default     = 512 # <-- CHANGE THIS: adjust for your workload

  validation {
    condition     = var.storage_node_memory_gb > 0
    error_message = "storage_node_memory_gb must be greater than 0."
  }
}

variable "storage_automatic_failover" {
  description = "Enable automatic failover for Memorystore cluster (if using Memorystore)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_automatic_failover ? true : false)
    error_message = "storage_automatic_failover must be a boolean."
  }
}

variable "storage_force_destroy" {
  description = "Force destroy Cloud Storage bucket on deletion (if using Cloud Storage)"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to force destroy

  validation {
    condition     = can(var.storage_force_destroy ? true : false)
    error_message = "storage_force_destroy must be a boolean."
  }
}

variable "storage_uniform_access" {
  description = "Enable uniform bucket level access for Cloud Storage bucket (if using Cloud Storage)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_uniform_access ? true : false)
    error_message = "storage_uniform_access must be a boolean."
  }
}

variable "storage_labels" {
  description = "Additional labels to apply to Persistent Disk (if using Persistent Disk)"
  type        = map(string)
  default = {
    workload = "gke"
    environment = var.environment
  }
}
