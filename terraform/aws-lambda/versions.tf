# ============================================================
# TEMPLATE: Terraform — AWS Lambda + API Gateway
# WHEN TO USE: Deploying serverless functions on AWS
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-lambda/
# MATURITY: Beta
# LAYOUT: versions.tf (providers), iam.tf (roles), lambda.tf (function),
#         api-gateway.tf (HTTP API), locals.tf (tags)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.51.0" # <-- CHANGE THIS: pin to latest stable
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
