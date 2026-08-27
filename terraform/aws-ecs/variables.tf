# ============================================================
# TEMPLATE: Terraform Variables — AWS ECS Fargate
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

# ---------------------------------------------
# Feature toggles — used only by the orchestrator (main.tf) to select
# which modules to run. Disabling "network"/"ecr"/"security_groups" breaks
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

variable "enable_security_groups" {
  description = "Provision the ALB and ECS task security groups"
  type        = bool
  default     = true
}

variable "enable_alb" {
  description = "Provision the Application Load Balancer"
  type        = bool
  default     = true
}

variable "enable_ecs" {
  description = "Provision the ECS cluster, task definition, and service"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Provision ECS service autoscaling (target tracking on CPU)"
  type        = bool
  default     = true
}
