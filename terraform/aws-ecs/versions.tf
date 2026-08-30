# ============================================================
# TEMPLATE: Terraform — AWS ECS Fargate
# WHEN TO USE: Running containers on AWS without managing servers
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-ecs/
# MATURITY: Stable
# LAYOUT: versions.tf (providers), network.tf (VPC), ecr.tf (registry),
#         ecs.tf (cluster/service), alb.tf (load balancer),
#         security-groups.tf, autoscaling.tf, locals.tf (tags)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "ecs/terraform.tfstate"
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
