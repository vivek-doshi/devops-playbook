# ============================================================
# TEMPLATE: Terraform — Azure Database Backup & DR Policies
# WHEN TO USE: Enable alongside terraform/azure-aks/ to ensure
#              Azure Database for PostgreSQL Flexible Server (or MySQL)
#              has automated backups, geo-redundancy, and PITR configured.
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: cd/kubernetes/_patterns/velero-backup.yaml
# MATURITY: Stable
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# ---------------------------------------------
# Private DNS Zone for Flexible Server
# ---------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.project}-${var.environment}.postgres.database.azure.com"
  resource_group_name = var.rg_name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "dns-link-postgres"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.rg_name
  registration_enabled  = false
}

# ---------------------------------------------
# PostgreSQL Flexible Server (Primary)
# ---------------------------------------------
resource "azurerm_postgresql_flexible_server" "primary" {
  name                = "psql-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location

  version    = var.db_version
  sku_name   = var.db_sku
  storage_mb = var.db_storage_mb

  # Credentials — store in Key Vault; retrieve with data source or use BYOK
  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_admin.result # generated below

  # Networking — private access only
  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  # ── Backup configuration ─────────────────────────────────────────────
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup # enables cross-region restore
  # ────────────────────────────────────────────────────────────────────

  # High Availability — zone-redundant for production
  high_availability {
    mode                      = "ZoneRedundant" # <-- CHANGE THIS: SameZone for lower cost
    standby_availability_zone = "2"             # <-- CHANGE THIS
  }

  maintenance_window {
    day_of_week  = 0 # Sunday
    start_hour   = 3 # 03:00 UTC  # <-- CHANGE THIS
    start_minute = 0
  }

  tags = merge(var.common_tags, { Component = "database" })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Generate a strong random password stored in Key Vault
resource "random_password" "db_admin" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# Store the generated password in Key Vault
resource "azurerm_key_vault_secret" "db_admin_password" {
  count        = var.key_vault_id != null ? 1 : 0
  name         = "db-admin-password"
  value        = random_password.db_admin.result
  key_vault_id = var.key_vault_id # <-- CHANGE THIS: supply an existing Key Vault ID

  # Set expiry so secret rotation (azure-keyvault-rotation.tf) triggers
  expiration_date = timeadd(timestamp(), "720h") # 30 days

  tags = var.common_tags
}

# ---------------------------------------------
# DB Subnet (separate from AKS subnet)
# ---------------------------------------------
resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.1.3.0/24"] # <-- CHANGE THIS: non-overlapping with AKS subnet

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ---------------------------------------------
# Geo-Replica in secondary region (DR target)
# Read replica in dr_location; promote manually during DR.
# ---------------------------------------------
resource "azurerm_postgresql_flexible_server" "dr_replica" {
  count = var.environment == "prod" ? 1 : 0 # <-- CHANGE THIS

  name                = "psql-${var.project}-${var.environment}-dr"
  resource_group_name = var.rg_name
  location            = var.dr_location

  # Geo-restore: source from the primary's latest backup
  create_mode                       = "GeoRestore"
  source_server_id                  = azurerm_postgresql_flexible_server.primary.id
  point_in_time_restore_time_in_utc = null # null = latest available backup

  version    = var.db_version
  sku_name   = var.db_sku
  storage_mb = var.db_storage_mb

  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_admin.result

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false # DR replica doesn't need geo-backup

  tags = merge(var.common_tags, { Component = "database", Role = "dr-replica" })
}

# ---------------------------------------------
# Azure Monitor Alert — backup failures
# ---------------------------------------------
resource "azurerm_monitor_metric_alert" "db_backup_failed" {
  name                = "alert-db-backup-failed-${local.name_prefix}"
  resource_group_name = var.rg_name
  scopes              = [azurerm_postgresql_flexible_server.primary.id]
  description         = "PostgreSQL Flexible Server backup has failed"
  severity            = 1 # Critical

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "backup_storage_used"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1 # alert if backup storage drops to zero
  }

  window_size = "P1D"
  frequency   = "PT1H"

  action {
    action_group_id = var.alert_action_group_id # <-- CHANGE THIS: pass in your action group
  }

  tags = var.common_tags
}
