# ============================================================
# TEMPLATE: Terraform Variables — AWS ECS Fargate
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
  description = "List of AZs to deploy across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # <-- CHANGE THIS: match your region
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080 # <-- CHANGE THIS: match your application
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512" # <-- CHANGE THIS: size to your workload
}

variable "task_memory" {
  description = "Memory (MB) for the Fargate task — must be compatible with CPU. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  type        = string
  default     = "1024" # <-- CHANGE THIS: size to your workload
}

variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum number of tasks (for autoscaling)"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of tasks (for autoscaling)"
  type        = number
  default     = 10
}
