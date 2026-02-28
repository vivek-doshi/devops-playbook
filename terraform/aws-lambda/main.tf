# ============================================================
# TEMPLATE: Terraform — AWS Lambda + API Gateway
# WHEN TO USE: Deploying serverless functions on AWS
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-lambda/
# MATURITY: Beta
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # <-- CHANGE THIS: pin to latest stable
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
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ---------------------------------------------
# IAM Role for Lambda
# ---------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "role-lambda-${var.project}-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Basic execution role (CloudWatch Logs access)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
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
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}"
  retention_in_days = 30
}

# ---------------------------------------------
# Lambda Function
# ---------------------------------------------
resource "aws_lambda_function" "main" {
  function_name = "${var.project}-${var.environment}"
  role          = aws_iam_role.lambda.arn
  handler       = var.handler       # <-- CHANGE THIS: e.g., "app.handler" for Python, "index.handler" for Node
  runtime       = var.runtime       # <-- CHANGE THIS: e.g., "python3.12", "nodejs20.x"
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Option 1: Deploy from a zip file (for initial setup — CI/CD updates this later)
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  # Option 2: Deploy from a container image (uncomment and remove filename/handler/runtime above)
  # package_type = "Image"
  # image_uri    = "${var.ecr_repository_url}:latest"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
      # <-- CHANGE THIS: add your application environment variables
    }
  }

  tracing_config {
    mode = "Active" # Enable AWS X-Ray tracing
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.lambda,
  ]
}

# ---------------------------------------------
# API Gateway (HTTP API — simpler and cheaper than REST API)
# ---------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "api-${var.project}-${var.environment}"
  protocol_type = "HTTP"
  description   = "HTTP API Gateway for ${var.project} (${var.environment})"

  cors_configuration {
    allow_headers = ["Content-Type", "Authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = var.cors_allowed_origins # <-- CHANGE THIS
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project}-${var.environment}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "lambda" {
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
