# ============================================================
# TEMPLATE: Terraform Outputs — Azure AKS
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = try(module.aks[0].name, null)
}

output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  value       = try(module.aks[0].id, null)
}

output "kube_config_command" {
  description = "Azure CLI command to get kubeconfig"
  value       = try("az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks[0].name}", null)
}

output "acr_login_server" {
  description = "ACR login server URL — use this in your Dockerfile push commands"
  value       = try(module.acr[0].login_server, null)
}

output "acr_name" {
  description = "ACR name"
  value       = try(module.acr[0].name, null)
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Insights"
  value       = try(module.monitoring[0].workspace_id, null)
}
