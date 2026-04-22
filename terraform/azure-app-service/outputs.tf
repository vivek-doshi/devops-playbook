# ============================================================
# TEMPLATE: Terraform Outputs — Azure App Service
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "app_service_name" {
  description = "Name of the App Service"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_linux_web_app.main.name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "app_service_url" {
  description = "Default URL of the App Service"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

# Note 5: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "staging_slot_url" {
  description = "URL of the staging deployment slot"
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}"
}

# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity (use for RBAC)"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

# Note 9: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "application_insights_connection_string" {
  description = "Application Insights connection string — add to app settings"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}
