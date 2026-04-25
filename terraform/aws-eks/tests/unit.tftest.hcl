# ============================================================
# TEMPLATE: Terraform Native Test — AWS EKS module
# WHEN TO USE: Validate module behavior before applying to real infra.
#   Run in PR checks; no AWS credentials required for mock tests.
# PREREQUISITES: Terraform >= 1.6.0
# HOW TO RUN:
#   cd terraform/aws-eks
#   terraform init
#   terraform test
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES:
#   terraform/aws-eks/main.tf
#   terraform/_testing/terratest/aws_eks_test.go  (Go integration tests)
# MATURITY: Stable
# ============================================================

# Note 1: mock_provider replaces the real AWS provider with an in-process mock.
# No AWS credentials needed; no API calls are made. Tests run in seconds.
# Remove mock_provider and add a real provider block for integration tests
# that create actual cloud resources (see the commented block at the bottom).
mock_provider "aws" {}

# Note 2: Variables defined here are shared by all run blocks below.
# They mirror the required variables in variables.tf — keep them in sync.
variables {
  project     = "test"
  environment = "test"
  aws_region  = "us-east-1"    # <-- CHANGE THIS: match your default region
  vpc_cidr    = "10.0.0.0/16"
  # Add any other required variables from your variables.tf  # <-- CHANGE THIS
}

# ── Test group: VPC configuration ────────────────────────────────────────

run "vpc_cidr_matches_input_variable" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == var.vpc_cidr
    error_message = "VPC CIDR block must match the vpc_cidr input variable"
  }
}

run "vpc_dns_settings_required_for_eks" {
  command = plan

  # Note 3: EKS requires both DNS settings. Nodes register their hostnames
  # via Route53 private zones. The API server resolves them this way.
  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "enable_dns_hostnames must be true — required for EKS node registration"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "enable_dns_support must be true — required for EKS"
  }
}

# ── Test group: Tagging convention ───────────────────────────────────────

run "required_tags_present_on_all_resources" {
  command = plan

  # Note 4: These tags flow from the AWS provider's default_tags block in main.tf.
  # All resources in the module inherit them automatically without explicit tagging.
  # The can() function returns true if the expression is valid (key exists).
  assert {
    condition     = can(aws_vpc.main.tags_all["project"])
    error_message = "'project' tag must be on all resources (set via provider default_tags)"
  }

  assert {
    condition     = can(aws_vpc.main.tags_all["environment"])
    error_message = "'environment' tag must be on all resources (set via provider default_tags)"
  }
}

run "resource_name_tag_includes_project_and_environment" {
  command = plan

  assert {
    condition     = can(regex("test.*test", aws_vpc.main.tags["Name"]))
    error_message = "Name tag must include both project ('test') and environment ('test')"
  }
}

# ── Test group: Security hardening ───────────────────────────────────────

# Note 5: Uncomment this test if your module has an endpoint_public_access variable.
# The EKS API server should not be publicly accessible in production.
#
# run "eks_api_endpoint_is_private" {
#   command = plan
#
#   assert {
#     condition     = aws_eks_cluster.main.vpc_config[0].endpoint_public_access == false
#     error_message = "EKS API server endpoint must be private — set endpoint_public_access = false"
#   }
#
#   assert {
#     condition     = aws_eks_cluster.main.vpc_config[0].endpoint_private_access == true
#     error_message = "EKS private endpoint access must be enabled"
#   }
# }

# ── Integration test (creates REAL resources) ────────────────────────────
# WARNING: Uncomment only in a DEDICATED TEST AWS ACCOUNT.
# Takes ~25 minutes and incurs charges. Resources are destroyed after the test.
# Remove the mock_provider "aws" {} block at the top before running apply tests.
#
# run "cluster_reaches_active_state" {
#   command = apply   # <-- Creates real AWS resources
#
#   assert {
#     condition     = aws_eks_cluster.main.status == "ACTIVE"
#     error_message = "EKS cluster must reach ACTIVE status after apply"
#   }
#
#   assert {
#     condition     = length(aws_eks_node_group.main) > 0
#     error_message = "At least one node group must be created"
#   }
# }
