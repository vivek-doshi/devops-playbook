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
  name_prefix  = "${var.project}-${var.environment}"
  storage_tags = merge(var.common_labels, { Component = "persistent-storage" })
}

# ---------------------------------------------
# Persistent Disk (if using Persistent Disk)
# ---------------------------------------------
resource "google_compute_disk" "main" {
  count  = var.enable_persistent_storage && var.storage_type == "persistent-disk" ? 1 : 0
  name   = "pd-${local.name_prefix}-${var.storage_class_name}"
  zone   = var.storage_zone
  size   = var.storage_size
  type   = var.storage_disk_type
  labels = local.storage_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------
# Cloud Storage Bucket (if using Cloud Storage)
# ---------------------------------------------
resource "google_storage_bucket" "main" {
  count                       = var.enable_persistent_storage && var.storage_type == "cloud-storage" ? 1 : 0
  name                        = "gs-${local.name_prefix}-${var.storage_class_name}"
  location                    = var.storage_location
  force_destroy               = var.storage_force_destroy
  uniform_bucket_level_access = var.storage_uniform_access
  labels                      = local.storage_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------
# Memorystore (if using Memorystore)
# ---------------------------------------------
resource "google_memorystore_instance" "main" {
  count         = var.enable_persistent_storage && var.storage_type == "memorystore" ? 1 : 0
  instance_id   = "mem-${local.name_prefix}"
  location      = var.storage_location
  shard_count   = var.storage_node_count
  replica_count = var.storage_automatic_failover ? 1 : 0 # <-- CHANGE THIS: replicas per shard
  node_type     = "SHARED_CORE_NANO"                     # <-- CHANGE THIS: match your workload sizing
  labels        = local.storage_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs are defined in outputs.tf
