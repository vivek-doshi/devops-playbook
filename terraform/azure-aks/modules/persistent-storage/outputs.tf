output "storage_type" {
  description = "Selected persistent-storage integration."
  value       = var.storage_type
}

output "storage_account_id" {
  description = "Azure Files storage account ID, or null when managed_disk is selected."
  value       = try(azurerm_storage_account.files[0].id, null)
}

output "file_share_id" {
  description = "Azure Files share resource ID, or null when managed_disk is selected."
  value       = try(azurerm_storage_share.main[0].id, null)
}
