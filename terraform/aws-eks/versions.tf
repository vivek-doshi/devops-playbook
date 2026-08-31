# ============================================================
# TEMPLATE: Terraform — Amazon Elastic Kubernetes Service (EKS)
# WHEN TO USE: Provisioning a production-ready EKS cluster on AWS
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-eks/, cd/kubernetes/
# MATURITY: Stable
# LAYOUT: versions.tf (providers), network.tf (VPC), ecr.tf (registry),
#         iam.tf (roles), eks.tf (cluster/node groups), security-groups.tf,
#         backup.tf (DR/backup), locals.tf (tags)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "eks/terraform.tfstate"
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

# Used by the optional cross-region RDS read replica in backup.tf.
provider "aws" {
  alias  = "dr_region"
  region = var.dr_region

  default_tags {
    tags = local.common_tags
  }
}
