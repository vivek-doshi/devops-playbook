# ---------------------------------------------
# FinOps tags and derived names shared across files
# ---------------------------------------------
locals {
  cluster_name = "eks-${var.project}-${var.environment}"
  common_tags = {
    CostCenter  = var.cost_center
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
