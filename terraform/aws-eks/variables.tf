# ============================================================
# TEMPLATE: Terraform Variables — AWS EKS
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  # Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "myapp" # <-- CHANGE THIS

  validation {
    condition     = length(trim(var.project)) > 0
    error_message = "Project must be a non-empty string."
  }
# Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "aws_region" {
  description = "AWS region for all resources"
  # Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "us-east-1" # <-- CHANGE THIS
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "availability_zones" {
  # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "List of AZs to deploy across — minimum 2 for high availability"
  type        = list(string)
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"] # <-- CHANGE THIS: match your region
}

# Note 11: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  # Note 12: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "10.0.0.0/16"
# Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "kubernetes_version" {
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Kubernetes version for EKS — see https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  type        = string
  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "1.29" # <-- CHANGE THIS: use latest stable
}

# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  # Note 17: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
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
