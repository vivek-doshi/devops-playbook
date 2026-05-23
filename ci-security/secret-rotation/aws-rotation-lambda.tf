# ============================================================
# TEMPLATE: Terraform — AWS Secrets Manager Rotation Lambda
# WHEN TO USE: Wire up automatic secret rotation for a DB password
#              stored in AWS Secrets Manager.
# PREREQUISITES: An existing secret in Secrets Manager, VPC with
#                private subnets that can reach the database.
# SECRETS NEEDED: None — Lambda IAM role uses least-privilege policy.
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: security/secret-rotation/aws-rotation-lambda.py
# MATURITY: Stable
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # <-- CHANGE THIS: pin to latest stable
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4.0"
    }
  }
}

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "project"     { type = string }
variable "environment" { type = string }

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret to rotate"
  type        = string
  # <-- CHANGE THIS: pass in from your root module or tfvars
}

variable "rotation_days" {
  description = "Rotate the secret every N days"
  type        = number
  default     = 30 # <-- CHANGE THIS
}

variable "vpc_id" {
  description = "VPC that contains the database"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets the rotation Lambda runs in (must reach the DB)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group of the RDS instance — Lambda SG gets ingress on db port"
  type        = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1" # <-- CHANGE THIS
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ---------------------------------------------
# Package the rotation Lambda
# ---------------------------------------------
data "archive_file" "rotation_lambda" {
  type        = "zip"
  source_file = "${path.module}/../../../security/secret-rotation/aws-rotation-lambda.py"
  output_path = "${path.module}/.build/rotation_lambda.zip"
}

# ---------------------------------------------
# Security Group for the Lambda (egress only)
# ---------------------------------------------
resource "aws_security_group" "rotation_lambda" {
  name        = "sg-secret-rotation-${local.name_prefix}"
  description = "Allow rotation Lambda to reach the database"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all egress — Lambda needs Secrets Manager endpoint + DB"
  }

  tags = { Name = "sg-secret-rotation-${local.name_prefix}" }
}

# Allow Lambda SG → DB SG on PostgreSQL port
resource "aws_security_group_rule" "db_from_rotation_lambda" {
  type                     = "ingress"
  from_port                = 5432 # <-- CHANGE THIS: 3306 for MySQL
  to_port                  = 5432 # <-- CHANGE THIS
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rotation_lambda.id
  security_group_id        = var.db_security_group_id
  description              = "Allow secret rotation Lambda to connect to DB"
}

# ---------------------------------------------
# IAM Role for the Rotation Lambda
# ---------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rotation_lambda" {
  name               = "role-secret-rotation-${local.name_prefix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "rotation_lambda_perms" {
  # Secrets Manager — only the specific secret
  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [var.secret_arn]
  }

  # VPC + CloudWatch Logs (managed policy covers this, but being explicit)
  statement {
    sid    = "VpcNetworkAccess"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "rotation_lambda_perms" {
  name   = "secret-rotation-perms"
  role   = aws_iam_role.rotation_lambda.id
  policy = data.aws_iam_policy_document.rotation_lambda_perms.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.rotation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------
# Rotation Lambda Function
# ---------------------------------------------
resource "aws_lambda_function" "secret_rotation" {
  function_name    = "fn-secret-rotation-${local.name_prefix}"
  filename         = data.archive_file.rotation_lambda.output_path
  source_code_hash = data.archive_file.rotation_lambda.output_base64sha256
  role             = aws_iam_role.rotation_lambda.arn
  handler          = "aws-rotation-lambda.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.rotation_lambda.id]
  }

  environment {
    variables = {
      AWS_REGION = var.aws_region
    }
  }

  tags = { Name = "fn-secret-rotation-${local.name_prefix}" }
}

# Grant Secrets Manager permission to invoke the Lambda
resource "aws_lambda_permission" "secrets_manager_invoke" {
  statement_id  = "SecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = var.secret_arn
}

# ---------------------------------------------
# Enable Rotation on the Secret
# ---------------------------------------------
resource "aws_secretsmanager_secret_rotation" "db_rotation" {
  secret_id           = var.secret_arn
  rotation_lambda_arn = aws_lambda_function.secret_rotation.arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  # Trigger an immediate rotation on first apply so you don't wait 30 days
  # Remove this if you want the first rotation to happen on schedule only
  depends_on = [aws_lambda_permission.secrets_manager_invoke]
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda"
  value       = aws_lambda_function.secret_rotation.arn
}
