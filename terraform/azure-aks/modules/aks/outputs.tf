output "name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
