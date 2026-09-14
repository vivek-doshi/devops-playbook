# ============================================================
# TEMPLATE: Terraform Outputs — GCP GKE Persistent Storage
# WHAT to CHANGE: Update descriptions or add additional outputs
# ============================================================

output "persistent_disk_id" {
  value = try(google_compute_disk.main[0].id, null)
  description = "ID of the Persistent Disk"
}

output "cloud_storage_bucket_id" {
  value = try(google_storage_bucket.main[0].id, null)
  description = "ID of the Cloud Storage bucket"
}

output "memorystore_cluster_id" {
  value = try(google_memorystore_cluster.main[0].id, null)
  description = "ID of the Memorystore cluster"
}

output "storage_type" {
  value = var.storage_type
  description = "Type of storage configured"
}
