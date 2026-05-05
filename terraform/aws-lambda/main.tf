# ============================================================
# TEMPLATE: Terraform — AWS Lambda + API Gateway
# WHEN TO USE: Deploying serverless functions on AWS
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-lambda/
# MATURITY: Beta
# ============================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    aws = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/aws"
      version = "~> 6.43.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "lambda/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "aws" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  region = var.aws_region

  default_tags {
    # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    tags = local.common_tags
  }
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# IAM Role for Lambda
# ---------------------------------------------
resource "aws_iam_role" "lambda" {
  # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name = "role-lambda-${var.project}-${var.environment}"

  assume_role_policy = jsonencode({
    # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Version = "2012-10-17"
    Statement = [{
      # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Action = "sts:AssumeRole"
      Effect = "Allow"
      # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Principal = {
        Service = "lambda.amazonaws.com"
      # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      }
    }]
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  })
}

# Basic execution role (CloudWatch Logs access)
# Note 15: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  # Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access (only needed if Lambda runs inside a VPC)
# resource "aws_iam_role_policy_attachment" "lambda_vpc" {
#   role       = aws_iam_role.lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }

# ---------------------------------------------
# CloudWatch Log Group
# ---------------------------------------------
# Note 17: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}"
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  retention_in_days = 30
}

# ---------------------------------------------
# Lambda Function
# ---------------------------------------------
# Note 19: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_lambda_function" "main" {
  function_name = "${var.project}-${var.environment}"
  # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  role          = aws_iam_role.lambda.arn
  handler       = var.handler       # <-- CHANGE THIS: e.g., "app.handler" for Python, "index.handler" for Node
  # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  runtime       = var.runtime       # <-- CHANGE THIS: e.g., "python3.12", "nodejs20.x"
  timeout       = var.timeout
  # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  memory_size   = var.memory_size

  # Option 1: Deploy from a zip file (for initial setup — CI/CD updates this later)
  filename         = var.lambda_zip_path
  # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  # Option 2: Deploy from a container image (uncomment and remove filename/handler/runtime above)
  # package_type = "Image"
  # image_uri    = "${var.ecr_repository_url}:latest"

  environment {
    # Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    variables = {
      ENVIRONMENT = var.environment
      # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
      # <-- CHANGE THIS: add your application environment variables
    }
  # Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  tracing_config {
    # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    mode = "Active" # Enable AWS X-Ray tracing
  }

  # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    # Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    aws_cloudwatch_log_group.lambda,
  ]
# Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# API Gateway (HTTP API — simpler and cheaper than REST API)
# ---------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name          = "api-${var.project}-${var.environment}"
  protocol_type = "HTTP"
  # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description   = "HTTP API Gateway for ${var.project} (${var.environment})"

  cors_configuration {
    # Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    allow_headers = ["Content-Type", "Authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    allow_origins = var.cors_allowed_origins # <-- CHANGE THIS
    max_age       = 3600
  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Note 36: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name        = "$default"
  auto_deploy = true

  # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    # Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    format = jsonencode({
      requestId      = "$context.requestId"
      # Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      # Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      # Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      status         = "$context.status"
      protocol       = "$context.protocol"
      # Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    # Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    })
  }
# Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  # Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name              = "/aws/apigateway/${var.project}-${var.environment}"
  retention_in_days = 30
# Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_apigatewayv2_integration" "lambda" {
  # Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.main.invoke_arn
  payload_format_version = "2.0"
}

# Catch-all route — Lambda handles all routing internally
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Allow API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
