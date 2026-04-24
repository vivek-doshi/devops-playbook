# ============================================================
# TEMPLATE: Terraform — AWS Remote State Bootstrap
# WHEN TO USE: Creating the shared S3 and DynamoDB backend before other AWS Terraform modules adopt remote state
# PREREQUISITES: AWS account, AWS CLI authenticated, local state for the first bootstrap apply
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: terraform/aws-eks/main.tf, terraform/aws-ecs/main.tf, terraform/aws-lambda/main.tf
# MATURITY: Stable
# ============================================================

# =====================================================================
# IMPORTANT:
# 1. Run this module ONCE using local state to create the remote backend.
# 2. After apply succeeds, uncomment the backend blocks in the other AWS Terraform modules.
# 3. Never run `terraform destroy` against this module in production, or every dependent state file becomes unavailable.
# =====================================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    aws = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "aws" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  region = local.aws_region

  default_tags {
    # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    tags = local.common_tags
  }
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Remote State Bucket
# ---------------------------------------------
# Note 9: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name # <-- CHANGE THIS: use a globally unique bucket name for your organisation

  # Note 10: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
  tags = merge(local.common_tags, {
    Name = local.state_bucket_name
  })
}

# Note 11: Versioning keeps previous state generations available for recovery after accidental writes or bad applies.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Note 12: AES256 server-side encryption protects state at rest without requiring an additional KMS bootstrap dependency.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Note 13: Blocking all public access settings prevents accidental exposure of state files through bucket policy drift.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note 14: Noncurrent version expiry controls storage growth while preserving a 90-day rollback window for state history.
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
# Note 15: DynamoDB state locking prevents concurrent applies from corrupting shared Terraform state.
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
# Note 16: Outputting the policy document keeps the bootstrap module auditable without attaching permissions to a guessed CI role.
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
  aws_region        = "us-east-1"                  # <-- CHANGE THIS: choose the region that will host your shared Terraform state
  project           = "devops-playbook"           # <-- CHANGE THIS: replace with your organisation or platform project name
  environment       = "shared"
  state_bucket_name = "devops-playbook-tfstate"   # <-- CHANGE THIS: must be globally unique across all AWS accounts
  lock_table_name   = "terraform-locks-shared"    # <-- CHANGE THIS: rename if your organisation uses a different lock-table standard

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "terraform-state"
  }
}
