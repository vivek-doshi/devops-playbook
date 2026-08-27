# ---------------------------------------------
# Application Insights (optional but recommended)
# ---------------------------------------------
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location
  application_type    = "web"

  tags = var.common_tags
}
