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
# Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "environment" {
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "dev" # <-- CHANGE THIS
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
