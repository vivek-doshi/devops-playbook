# ============================================================
# TEMPLATE: Terraform Variables — AWS Lambda
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

variable "runtime" {
  description = "Lambda runtime — see https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html"
  type        = string
  default     = "python3.12" # <-- CHANGE THIS: python3.12, nodejs20.x, dotnet8, java21, etc.
}

variable "handler" {
  description = "Lambda function handler (entry point)"
  type        = string
  default     = "app.handler" # <-- CHANGE THIS: e.g., index.handler for Node.js
}

variable "memory_size" {
  description = "Memory allocated to the Lambda function (MB) — CPU scales proportionally"
  type        = number
  default     = 256 # <-- CHANGE THIS: 128-10240 MB
}

variable "timeout" {
  description = "Lambda function timeout in seconds (max 900 = 15 minutes)"
  type        = number
  default     = 30 # <-- CHANGE THIS
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
  default     = "lambda.zip" # <-- CHANGE THIS: path to your zip
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for API Gateway"
  type        = list(string)
  default     = ["*"] # <-- CHANGE THIS: restrict in production
}
