# ============================================================
# TEMPLATE: Terraform — GCP GKE Persistent Storage
# WHEN to USE: Add alongside terraform/gcp-gke/ to ensure GKE workloads have
#              persistent storage (Persistent Disk, Cloud Storage, or Memorystore)
#              configured before an incident forces your hand.
# WHAT to CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: docs/guides/gke-persistent-storage.md
# MATURITY: Stable
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  storage_tags = merge(var.common_labels, { Component = "persistent-storage" })
}

# ---------------------------------------------
# Persistent Disk (if using Persistent Disk)
# ---------------------------------------------
resource "google_compute_disk" "main" {
  count = var.enable_persistent_storage && var.storage_type == "persistent-disk" ? 1 : 0
  name = "pd-${local.name_prefix}-${var.storage_class_name}"
  zone = var.storage_zone
  size = var.storage_size
  type = var.storage_disk_type
  labels = var.storage_labels

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Cloud Storage Bucket (if using Cloud Storage)
# ---------------------------------------------
resource "google_storage_bucket" "main" {
  count = var.enable_persistent_storage && var.storage_type == "cloud-storage" ? 1 : 0
  name = "gs-${local.name_prefix}-${var.storage_class_name}"
  location = var.storage_location
  force_destroy = var.storage_force_destroy
  uniform_bucket_level_access = var.storage_uniform_access

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Memorystore (if using Memorystore)
# ---------------------------------------------
resource "google_memorystore_cluster" "main" {
  count = var.enable_persistent_storage && var.storage_type == "memorystore" ? 1 : 0
  name = "mem-${local.name_prefix}"
  location = var.storage_location
  tier = var.storage_tier
  node_count = var.storage_node_count
  node_memory_gb = var.storage_node_memory_gb
  enable_automatic_failover = var.storage_automatic_failover

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Storage Class Output
# ---------------------------------------------
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
