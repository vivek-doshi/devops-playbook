# ---------------------------------------------
# Azure Container Registry (ACR)
# ---------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = replace("acr${var.project}${var.environment}", "-", "") # ACR names must be alphanumeric
  resource_group_name = var.rg_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identity instead of admin credentials

  tags = var.common_tags
}
