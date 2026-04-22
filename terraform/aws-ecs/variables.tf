# ============================================================
# TEMPLATE: Terraform Variables — AWS ECS Fargate
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "myapp" # <-- CHANGE THIS
}

variable "environment" {
  # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "aws_region" {
  description = "AWS region for all resources"
  # Note 5: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "us-east-1" # <-- CHANGE THIS
}

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "availability_zones" {
  description = "List of AZs to deploy across"
  type        = list(string)
  # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = ["us-east-1a", "us-east-1b"] # <-- CHANGE THIS: match your region
}

variable "vpc_cidr" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "container_port" {
  description = "Port the container listens on"
  # Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = number
  default     = 8080 # <-- CHANGE THIS: match your application
}

# Note 11: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)"
  type        = string
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "512" # <-- CHANGE THIS: size to your workload
}

variable "task_memory" {
  # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Memory (MB) for the Fargate task — must be compatible with CPU. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html"
  type        = string
  default     = "1024" # <-- CHANGE THIS: size to your workload
# Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "desired_count" {
  description = "Desired number of running tasks"
  # Note 15: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = number
  default     = 2
}

# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "min_count" {
  description = "Minimum number of tasks (for autoscaling)"
  type        = number
  # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = 1
}

variable "max_count" {
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Maximum number of tasks (for autoscaling)"
  type        = number
  default     = 10
}
