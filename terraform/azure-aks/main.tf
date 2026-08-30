# ============================================================
# ORCHESTRATOR — selects and wires the feature modules below.
# Toggle a feature by setting its `enable_*` variable to false.
# No resources are defined directly in this file — only module calls.
# ============================================================

module "network" {
  count  = var.enable_network ? 1 : 0
  source = "./modules/network"

  project            = var.project
  environment        = var.environment
  rg_name            = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  vnet_address_space = var.vnet_address_space
  aks_subnet_prefix  = var.aks_subnet_prefix
  common_tags        = local.common_tags
}

module "acr" {
  count  = var.enable_acr ? 1 : 0
  source = "./modules/acr"

  project     = var.project
  environment = var.environment
  rg_name     = azurerm_resource_group.main.name
  location    = azurerm_resource_group.main.location
  acr_sku     = var.acr_sku
  common_tags = local.common_tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  project     = var.project
  environment = var.environment
  rg_name     = azurerm_resource_group.main.name
  location    = azurerm_resource_group.main.location
  common_tags = local.common_tags
}

module "aks" {
  count  = var.enable_aks ? 1 : 0
  source = "./modules/aks"

  project                    = var.project
  environment                = var.environment
  rg_name                    = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  kubernetes_version         = var.kubernetes_version
  node_count                 = var.node_count
  node_vm_size               = var.node_vm_size
  aks_subnet_id              = try(module.network[0].aks_subnet_id, null)
  enable_autoscaling         = var.enable_autoscaling
  node_min_count             = var.node_min_count
  node_max_count             = var.node_max_count
  log_analytics_workspace_id = try(module.monitoring[0].workspace_id, null)
  common_tags                = local.common_tags

  gpu_node_pool_enabled    = var.gpu_node_pool_enabled
  gpu_node_pool_name       = var.gpu_node_pool_name
  gpu_node_vm_size         = var.gpu_node_vm_size
  gpu_enable_autoscaling   = var.gpu_enable_autoscaling
  gpu_node_count           = var.gpu_node_count
  gpu_node_min_count       = var.gpu_node_min_count
  gpu_node_max_count       = var.gpu_node_max_count
  gpu_node_os_disk_size_gb = var.gpu_node_os_disk_size_gb
  gpu_node_labels          = var.gpu_node_labels
  gpu_node_taint_enabled   = var.gpu_node_taint_enabled
}

module "acr_rbac" {
  count  = var.enable_acr && var.enable_aks ? 1 : 0
  source = "./modules/acr-rbac"

  acr_id                         = try(module.acr[0].id, null)
  aks_kubelet_identity_object_id = try(module.aks[0].kubelet_identity_object_id, null)
}

module "backup" {
  count  = var.enable_backup ? 1 : 0
  source = "./modules/backup"

  project     = var.project
  environment = var.environment
  rg_name     = azurerm_resource_group.main.name
  location    = azurerm_resource_group.main.location
  vnet_id     = try(module.network[0].vnet_id, null)
  vnet_name   = try(module.network[0].vnet_name, null)
  common_tags = local.common_tags

  db_admin_username     = var.db_admin_username
  db_sku                = var.db_sku
  db_storage_mb         = var.db_storage_mb
  db_version            = var.db_version
  backup_retention_days = var.backup_retention_days
  geo_redundant_backup  = var.geo_redundant_backup
  dr_location           = var.dr_location
  key_vault_id          = var.key_vault_id
  alert_action_group_id = var.alert_action_group_id
}