# ---------------------------------------------
# App Service (Linux Web App)
# ---------------------------------------------
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project}-${var.environment}" # <-- CHANGE THIS: must be globally unique
  resource_group_name = var.rg_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  https_only          = true

  site_config {
    always_on = var.sku_name != "F1" # Free tier doesn't support always_on

    # Configure the runtime stack — uncomment ONE of the following:
    application_stack {
      # dotnet_version = "8.0"        # <-- CHANGE THIS: .NET 8
      # node_version   = "20-lts"     # <-- CHANGE THIS: Node.js 20
      # python_version = "3.12"       # <-- CHANGE THIS: Python 3.12
      # java_version   = "17"         # <-- CHANGE THIS: Java 17
      docker_image_name        = "${var.docker_image}:latest" # <-- CHANGE THIS: or use a specific tag
      docker_registry_url      = var.docker_registry_url
      docker_registry_username = var.docker_registry_username
      docker_registry_password = var.docker_registry_password
    }

    health_check_path = "/health" # <-- CHANGE THIS: your health endpoint
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "ASPNETCORE_ENVIRONMENT"              = var.environment == "prod" ? "Production" : "Development" # <-- CHANGE THIS: for non-.NET apps
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.common_tags
}
