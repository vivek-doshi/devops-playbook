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

# ---------------------------------------------
# Module Integration Variables
# ---------------------------------------------
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "myapp" # <-- CHANGE THIS

  validation {
    condition     = length(trimspace(var.project)) > 0
    error_message = "Project must be a non-empty string."
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

variable "vpc_id" {
  description = "VPC ID for storage resources"
  type        = string
  default     = null # <-- CHANGE THIS: match your VPC

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.vpc_id))
    error_message = "vpc_id must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block for storage resources"
  type        = string
  default     = "10.0.0.0/16" # <-- CHANGE THIS: match your VPC

  validation {
    condition     = can(regex("^10\\.[0-9]+\\.[0-9]+\\.[0-9]+/16$", var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for storage resources"
  type        = list(string)
  default     = [] # <-- CHANGE THIS: match your subnets

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "private_subnet_ids must be a non-empty list."
  }
}

variable "availability_zones" {
  description = "Availability zones for EFS file system (if using EFS)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # <-- CHANGE THIS: match your AZs
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    workload = "eks"
  }
}
