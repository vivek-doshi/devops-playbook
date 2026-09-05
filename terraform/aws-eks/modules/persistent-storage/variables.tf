# ============================================================
# TEMPLATE: Terraform Variables — AWS EKS Persistent Storage
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "enable_persistent_storage" {
  description = "Enable persistent storage for EKS workloads"
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
  default     = "ebs" # <-- CHANGE THIS: ebs, efs, or s3

  validation {
    condition     = contains(["ebs", "efs", "s3"], var.storage_type)
    error_message = "storage_type must be one of: ebs, efs, or s3."
  }
}

variable "storage_class_name" {
  description = "Name of the storage class (for EBS)"
  type        = string
  default     = "standard" # <-- CHANGE THIS: standard, gp2, gp3, or io1

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_class_name))
    error_message = "storage_class_name must contain only lowercase letters and numbers."
  }
}

variable "storage_size" {
  description = "Size of the EBS volume in GB (if using EBS)"
  type        = number
  default     = 100 # <-- CHANGE THIS: size to your workload

  validation {
    condition     = var.storage_size > 0
    error_message = "storage_size must be greater than 0."
  }
}

variable "storage_iops" {
  description = "IOPS for the EBS volume (if using EBS)"
  type        = number
  default     = 3000 # <-- CHANGE THIS: adjust for I/O intensive workloads

  validation {
    condition     = var.storage_iops > 0
    error_message = "storage_iops must be greater than 0."
  }
}

variable "storage_throughput" {
  description = "Throughput for the EBS volume in MB/s (if using EBS)"
  type        = number
  default     = 50 # <-- CHANGE THIS: adjust for throughput intensive workloads

  validation {
    condition     = var.storage_throughput > 0
    error_message = "storage_throughput must be greater than 0."
  }
}

variable "storage_volume_type" {
  description = "Volume type for EBS volume (if using EBS)"
  type        = string
  default     = "gp3" # <-- CHANGE THIS: gp2, gp3, or io1

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.storage_volume_type)
    error_message = "storage_volume_type must be one of: gp2, gp3, or io1."
  }
}

variable "storage_performance_mode" {
  description = "Performance mode for EFS file system (if using EFS)"
  type        = string
  default     = "performance" # <-- CHANGE THIS: performance or general-purpose

  validation {
    condition     = contains(["performance", "general-purpose"], var.storage_performance_mode)
    error_message = "storage_performance_mode must be one of: performance or general-purpose."
  }
}

variable "storage_throughput_mode" {
  description = "Throughput mode for EFS file system (if using EFS)"
  type        = string
  default     = "bursting" # <-- CHANGE THIS: bursting or provisioned

  validation {
    condition     = contains(["bursting", "provisioned"], var.storage_throughput_mode)
    error_message = "storage_throughput_mode must be one of: bursting or provisioned."
  }
}

variable "storage_encryption" {
  description = "Enable encryption for EFS file system (if using EFS)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable encryption

  validation {
    condition     = can(var.storage_encryption ? true : false)
    error_message = "storage_encryption must be a boolean."
  }
}

variable "storage_multi_attached" {
  description = "Enable multi-attached volume for EBS (if using EBS)"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true for multi-attached volumes

  validation {
    condition     = can(var.storage_multi_attached ? true : false)
    error_message = "storage_multi_attached must be a boolean."
  }
}

variable "storage_force_destroy" {
  description = "Force destroy S3 bucket on deletion (if using S3)"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to force destroy

  validation {
    condition     = can(var.storage_force_destroy ? true : false)
    error_message = "storage_force_destroy must be a boolean."
  }
}
