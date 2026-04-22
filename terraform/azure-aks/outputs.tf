# ============================================================
# TEMPLATE: Terraform Outputs — Azure AKS
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "resource_group_name" {
  description = "Name of the resource group"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_resource_group.main.name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_kubernetes_cluster.main.name
}

# Note 5: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "aks_cluster_id" {
  description = "Resource ID of the AKS cluster"
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_kubernetes_cluster.main.id
}

# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "kube_config_command" {
  description = "Azure CLI command to get kubeconfig"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

# Note 9: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "acr_login_server" {
  description = "ACR login server URL — use this in your Dockerfile push commands"
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = azurerm_container_registry.main.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = azurerm_container_registry.main.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container Insights"
  value       = azurerm_log_analytics_workspace.main.id
}
