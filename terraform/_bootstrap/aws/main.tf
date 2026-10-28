# ============================================================
# TEMPLATE: Terraform — AWS Remote State Bootstrap
# WHEN TO USE: Creating the shared S3 and DynamoDB backend before other AWS Terraform modules adopt remote state
# PREREQUISITES: AWS account, AWS CLI authenticated, local state for the first bootstrap apply
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: terraform/aws-eks/main.tf, terraform/aws-ecs/main.tf, terraform/aws-lambda/main.tf
# SUPPORT: template
# MATURITY: Template
# ============================================================

# =====================================================================
# IMPORTANT:
# 1. Run this module ONCE using local state to create the remote backend.
# 2. After apply succeeds, uncomment the backend blocks in the other AWS Terraform modules.
# 3. Never run `terraform destroy` against this module in production, or every dependent state file becomes unavailable.
# =====================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # <-- CHANGE THIS: pin to latest stable
    }
  }
}

provider "aws" {
  region = local.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# ---------------------------------------------
# Remote State Bucket
# ---------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name # <-- CHANGE THIS: use a globally unique bucket name for your organisation

  tags = merge(local.common_tags, {
    Name = local.state_bucket_name
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    # Note 14a: An explicit empty filter keeps the rule scoped to the whole bucket while satisfying provider validation.
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ---------------------------------------------
# DynamoDB Lock Table
# ---------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = local.lock_table_name
  })
}

# ---------------------------------------------
# IAM Policy Document for CI
# ---------------------------------------------
data "aws_iam_policy_document" "terraform_backend_access" {
  statement {
    sid    = "ListStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.terraform_state.arn]
  }

  statement {
    sid    = "ReadWriteStateObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = ["${aws_s3_bucket.terraform_state.arn}/*"]
  }

  statement {
    sid    = "UseStateLockTable"
    effect = "Allow"

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]

    resources = [aws_dynamodb_table.terraform_locks.arn]
  }
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "state_bucket_name" {
  description = "S3 bucket name to copy into backend \"s3\" bucket settings in the other AWS Terraform modules."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name to copy into backend \"s3\" dynamodb_table settings for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_region" {
  description = "AWS region to copy into backend \"s3\" region settings in the dependent Terraform modules."
  value       = local.aws_region
}

output "ci_backend_policy_json" {
  description = "Minimum IAM policy document a CI role needs to read, write, and lock this shared Terraform backend."
  value       = data.aws_iam_policy_document.terraform_backend_access.json
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  aws_region        = "us-east-1"       # <-- CHANGE THIS: choose the region that will host your shared Terraform state
  project           = "devops-playbook" # <-- CHANGE THIS: replace with your organisation or platform project name
  environment       = "shared"
  state_bucket_name = "devops-playbook-tfstate" # <-- CHANGE THIS: must be globally unique across all AWS accounts
  lock_table_name   = "terraform-locks-shared"  # <-- CHANGE THIS: rename if your organisation uses a different lock-table standard

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "terraform-state"
  }
}
