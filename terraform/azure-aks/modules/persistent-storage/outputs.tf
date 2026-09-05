# ============================================================
# TEMPLATE: Terraform Outputs — Azure AKS Persistent Storage
# WHAT to CHANGE: Update descriptions or add additional outputs
# ============================================================

output "disk_id" {
  value = try(azurerm_disk.main[0].id, null)
  description = "ID of the Azure Disk"
}

output "file_share_id" {
  value = try(azurerm_file_share.main[0].id, null)
  description = "ID of the Azure File Share"
}

output "blob_container_id" {
  value = try(azurerm_storage_container.main[0].id, null)
  description = "ID of the Azure Blob Storage container"
}

output "storage_type" {
  value = var.storage_type
  description = "Type of storage configured"
}
