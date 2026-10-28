# ============================================================
# AKS persistent storage prerequisites
# Azure Disk is dynamically provisioned by the AKS Azure Disk CSI driver and
# therefore does not need a pre-created azurerm_disk resource. This module
# provisions Azure Files infrastructure for a shared, static file share.
# Kubernetes StorageClasses and PVCs remain application configuration.
# ============================================================

locals {
  name_prefix  = "${var.project}${var.environment}"
  storage_name = lower(replace("st${local.name_prefix}", "-", ""))
  storage_tags = merge(var.common_tags, { Component = "persistent-storage" })
}

resource "azurerm_storage_account" "files" {
  count = var.enable_persistent_storage && var.storage_type == "azure_file" ? 1 : 0

  name                            = substr(local.storage_name, 0, 24)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_account_replication_type
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = var.public_network_access_enabled
  shared_access_key_enabled       = false
  allow_nested_items_to_be_public = false
  tags                            = local.storage_tags
}

resource "azurerm_storage_share" "main" {
  count = var.enable_persistent_storage && var.storage_type == "azure_file" ? 1 : 0

  name               = var.file_share_name
  storage_account_id = azurerm_storage_account.files[0].id
  quota              = var.file_share_quota_gb
  enabled_protocol    = "SMB"
}
