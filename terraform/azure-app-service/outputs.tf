# ============================================================
# TEMPLATE: Terraform Outputs — Azure App Service
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "app_service_name" {
  description = "Name of the App Service"
  value       = try(module.web_app[0].name, null)
}

output "app_service_url" {
  description = "Default URL of the App Service"
  value       = try("https://${module.web_app[0].default_hostname}", null)
}

output "staging_slot_url" {
  description = "URL of the staging deployment slot"
  value       = try("https://${module.staging_slot[0].default_hostname}", null)
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity (use for RBAC)"
  value       = try(module.web_app[0].identity_principal_id, null)
}

output "application_insights_connection_string" {
  description = "Application Insights connection string — add to app settings"
  value       = try(module.monitoring[0].connection_string, null)
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}
