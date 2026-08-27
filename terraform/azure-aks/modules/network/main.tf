# ---------------------------------------------
# Virtual Network + Subnet for AKS
# ---------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = [var.vnet_address_space]

  tags = var.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_prefix]
}
