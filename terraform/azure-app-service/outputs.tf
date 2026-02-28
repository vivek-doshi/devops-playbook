# ============================================================
# TEMPLATE: Terraform Outputs — Azure App Service
# ============================================================

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_url" {
  description = "Default URL of the App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "staging_slot_url" {
  description = "URL of the staging deployment slot"
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity (use for RBAC)"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string — add to app settings"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}
