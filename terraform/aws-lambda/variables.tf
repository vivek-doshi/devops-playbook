# ============================================================
# TEMPLATE: Terraform Variables — AWS Lambda
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "myapp" # <-- CHANGE THIS

  validation {
    condition     = length(trim(var.project)) > 0
    error_message = "Project must be a non-empty string."
  }
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
  # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
# Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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
  # Note 5: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "us-east-1" # <-- CHANGE THIS
}

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "runtime" {
  description = "Lambda runtime — see https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html"
  type        = string
  # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "python3.12" # <-- CHANGE THIS: python3.12, nodejs20.x, dotnet8, java21, etc.
}

variable "handler" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Lambda function handler (entry point)"
  type        = string
  default     = "app.handler" # <-- CHANGE THIS: e.g., index.handler for Node.js
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "memory_size" {
  description = "Memory allocated to the Lambda function (MB) — CPU scales proportionally"
  # Note 10: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = number
  default     = 256 # <-- CHANGE THIS: 128-10240 MB
}

# Note 11: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "timeout" {
  description = "Lambda function timeout in seconds (max 900 = 15 minutes)"
  type        = number
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = 30 # <-- CHANGE THIS
}

variable "lambda_zip_path" {
  # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
  default     = "lambda.zip" # <-- CHANGE THIS: path to your zip
# Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for API Gateway"
  # Note 15: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = list(string)
  default     = ["*"] # <-- CHANGE THIS: restrict in production
}
