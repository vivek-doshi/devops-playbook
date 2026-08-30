# ---------------------------------------------
# Staging Slot (for zero-downtime deployments)
# ---------------------------------------------
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = var.app_service_id
  https_only     = true

  site_config {
    always_on         = var.sku_name != "F1"
    health_check_path = "/health"

    application_stack {
      docker_image_name        = "${var.docker_image}:latest"
      docker_registry_url      = var.docker_registry_url
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ASPNETCORE_ENVIRONMENT"              = "Staging"
  }

  tags = var.common_tags
}
