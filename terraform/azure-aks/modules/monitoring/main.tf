# ---------------------------------------------
# Log Analytics Workspace (for Container Insights)
# ---------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.common_tags
}
