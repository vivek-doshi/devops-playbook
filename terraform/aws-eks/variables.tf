# ============================================================
# TEMPLATE: Terraform Variables — AWS EKS
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
