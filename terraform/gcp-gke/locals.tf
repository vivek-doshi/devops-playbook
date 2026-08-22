locals {
  common_labels = {
    project     = var.project
    environment = var.environment
    managed-by  = "terraform"
  }
}
