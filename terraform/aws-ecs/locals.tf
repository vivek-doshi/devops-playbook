# ---------------------------------------------
# FinOps tags applied to every resource via provider default_tags
# ---------------------------------------------
locals {
  common_tags = {
    CostCenter  = var.cost_center
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
