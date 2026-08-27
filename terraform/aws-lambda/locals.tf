locals {
  common_tags = {
    CostCenter  = var.cost_center
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
