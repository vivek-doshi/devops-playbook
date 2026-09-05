# ============================================================
# TEMPLATE: Terraform — Azure AKS Persistent Storage
# WHEN to USE: Add alongside terraform/azure-aks/ to ensure AKS workloads have
#              persistent storage (Azure Disk, Azure File, or Azure Blob)
#              configured before an incident forces your hand.
# WHAT to CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: docs/guides/aks-persistent-storage.md
# MATURITY: Stable
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  storage_tags = merge(var.common_tags, { Component = "persistent-storage" })
}

# ---------------------------------------------
# Azure Disk (if using Azure Disk)
# ---------------------------------------------
resource "azurerm_disk" "main" {
  count = var.enable_persistent_storage && var.storage_type == "disk" ? 1 : 0
  name = "disk-${local.name_prefix}-${var.storage_class_name}"
  resource_group_name = var.storage_resource_group_name
  location = var.storage_location
  size = var.storage_size
  sku = var.storage_sku
  zone = var.storage_zone

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Azure File Share (if using Azure File Share)
# ---------------------------------------------
resource "azurerm_file_share" "main" {
  count = var.enable_persistent_storage && var.storage_type == "file-share" ? 1 : 0
  name = "fileshare-${local.name_prefix}-${var.storage_class_name}"
  resource_group_name = var.storage_resource_group_name
  location = var.storage_location
  access_tier = var.storage_access_tier
  enable_https = var.storage_enable_https
  network_acl = var.storage_network_acl

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Azure Blob Storage (if using Azure Blob Storage)
# ---------------------------------------------
resource "azurerm_storage_container" "main" {
  count = var.enable_persistent_storage && var.storage_type == "blob-storage" ? 1 : 0
  name = "blob-${local.name_prefix}-${var.storage_class_name}"
  resource_group_name = var.storage_resource_group_name
  location = var.storage_location

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Storage Class Output
# ---------------------------------------------
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
