# ============================================================
# ORCHESTRATOR — selects and wires the feature modules below.
# Toggle a feature by setting its `enable_*` variable to false.
# No resources are defined directly in this file — only module calls.
# ============================================================

module "app_service_plan" {
  count  = var.enable_app_service_plan ? 1 : 0
  source = "./modules/app-service-plan"

  project     = var.project
  environment = var.environment
  rg_name     = azurerm_resource_group.main.name
  location    = azurerm_resource_group.main.location
  os_type     = var.os_type
  sku_name    = var.sku_name
  common_tags = local.common_tags
}

module "web_app" {
  count  = var.enable_web_app ? 1 : 0
  source = "./modules/web-app"

  project                  = var.project
  environment              = var.environment
  rg_name                  = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  service_plan_id          = try(module.app_service_plan[0].id, null)
  sku_name                 = var.sku_name
  docker_image             = var.docker_image
  docker_registry_url      = var.docker_registry_url
  docker_registry_username = var.docker_registry_username
  docker_registry_password = var.docker_registry_password
  common_tags              = local.common_tags
}

module "staging_slot" {
  count  = var.enable_staging_slot ? 1 : 0
  source = "./modules/staging-slot"

  app_service_id           = try(module.web_app[0].id, null)
  sku_name                 = var.sku_name
  docker_image             = var.docker_image
  docker_registry_url      = var.docker_registry_url
  docker_registry_username = var.docker_registry_username
  docker_registry_password = var.docker_registry_password
  common_tags              = local.common_tags
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
