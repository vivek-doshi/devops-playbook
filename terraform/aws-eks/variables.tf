# ============================================================
# TEMPLATE: Terraform Variables — AWS EKS
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

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1" # <-- CHANGE THIS
}

variable "availability_zones" {
  description = "List of AZs to deploy across — minimum 2 for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"] # <-- CHANGE THIS: match your region
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS — see https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  type        = string
  default     = "1.29" # <-- CHANGE THIS: use latest stable
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.large" # <-- CHANGE THIS: size to your workload
}

variable "node_desired_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_count" {
  description = "Minimum number of worker nodes (for autoscaling)"
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum number of worker nodes (for autoscaling)"
  type        = number
  default     = 10
}

variable "gpu_node_group_enabled" {
  description = "Create a separate GPU-enabled managed node group for training or inference workloads"
  type        = bool
  default     = false
}

variable "gpu_instance_types" {
  description = "EC2 instance types for the GPU node group"
  type        = list(string)
  default     = ["g5.xlarge"] # <-- CHANGE THIS: pick the GPU family that matches your workload
}

variable "gpu_capacity_type" {
  description = "Capacity type for the GPU node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.gpu_capacity_type)
    error_message = "gpu_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "gpu_desired_count" {
  description = "Desired number of GPU worker nodes"
  type        = number
  default     = 1
}

variable "gpu_min_count" {
  description = "Minimum number of GPU worker nodes (for autoscaling)"
  type        = number
  default     = 0
}

variable "gpu_max_count" {
  description = "Maximum number of GPU worker nodes (for autoscaling)"
  type        = number
  default     = 3
}

variable "gpu_disk_size" {
  description = "Disk size in GiB for GPU worker nodes"
  type        = number
  default     = 150
}

variable "gpu_ami_type" {
  description = "AMI type for the GPU node group"
  type        = string
  default     = "AL2_x86_64_GPU"

  validation {
    condition = contains([
      "AL2_x86_64_GPU",
      "BOTTLEROCKET_X86_64_NVIDIA",
      "AL2023_X86_64_NVIDIA"
    ], var.gpu_ami_type)
    error_message = "gpu_ami_type must be a supported GPU AMI type for EKS managed node groups."
  }
}

variable "gpu_labels" {
  description = "Additional Kubernetes labels to apply to the GPU node group"
  type        = map(string)
  default = {
    accelerator = "nvidia-gpu"
    workload    = "ml"
  }
}

variable "gpu_node_taint_enabled" {
  description = "Apply a NoSchedule taint to the GPU node group so only explicit ML workloads land on it"
  type        = bool
  default     = true
}

# ---------------------------------------------
# Feature toggles — used only by the orchestrator (main.tf) to select
# which modules to run. Disabling "network"/"iam"/"security_groups" breaks
# dependent modules unless you also disable everything that depends on them.
# ---------------------------------------------
variable "enable_network" {
  description = "Provision the VPC, subnets, and networking (core dependency for other modules)"
  type        = bool
  default     = true
}

variable "enable_ecr" {
  description = "Provision the ECR repository"
  type        = bool
  default     = true
}

variable "enable_iam" {
  description = "Provision the EKS cluster and node IAM roles (core dependency for the eks module)"
  type        = bool
  default     = true
}

variable "enable_security_groups" {
  description = "Provision the EKS cluster control plane security group"
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "Provision the EKS cluster and managed node groups"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Provision the RDS backup/DR stack (modules/backup)"
  type        = bool
  default     = false
}

# ---------------------------------------------
# Backup / DR (modules/backup) — only used when enable_backup = true
# ---------------------------------------------
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium" # <-- CHANGE THIS
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres" # <-- CHANGE THIS: postgres | mysql | mariadb
}

variable "db_engine_version" {
  type    = string
  default = "16.1" # <-- CHANGE THIS: use latest stable
}

variable "db_name" {
  type    = string
  default = "appdb" # <-- CHANGE THIS
}

variable "backup_retention_days" {
  description = "Days to retain automated backups (1-35)"
  type        = number
  default     = 14 # <-- CHANGE THIS: 30 for compliance-sensitive workloads
}

variable "backup_window" {
  description = "UTC window for automated backups — must not overlap maintenance_window"
  type        = string
  default     = "02:00-03:00" # <-- CHANGE THIS: pick off-peak for your region
}

variable "maintenance_window" {
  type    = string
  default = "Mon:04:00-Mon:05:00" # <-- CHANGE THIS
}

variable "dr_region" {
  description = "Region for the cross-region read replica (DR target)"
  type        = string
  default     = "us-west-2" # <-- CHANGE THIS
}

variable "snapshot_s3_bucket" {
  description = "S3 bucket for exported snapshots (DR archive)"
  type        = string
  default     = "" # <-- CHANGE THIS: leave empty to skip export
}

# ---------------------------------------------
# Persistent Storage (modules/persistent-storage)
# ---------------------------------------------
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
