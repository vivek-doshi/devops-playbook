# ---------------------------------------------
# App Service Plan
# ---------------------------------------------
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.common_tags
}
