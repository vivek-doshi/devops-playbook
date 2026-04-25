# ============================================================
# TEMPLATE: Terraform — Azure Database Backup & DR Policies
# WHEN TO USE: Add alongside terraform/azure-aks/main.tf to ensure
#              Azure Database for PostgreSQL Flexible Server (or MySQL)
#              has automated backups, geo-redundancy, and PITR configured.
# PREREQUISITES: Existing resource group and VNet from main.tf.
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: terraform/azure-aks/main.tf
#                cd/kubernetes/_patterns/velero-backup.yaml
# MATURITY: Stable
# ============================================================

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "db_admin_username" {
  description = "PostgreSQL administrator login"
  type        = string
  default     = "dbadmin"             # <-- CHANGE THIS
}

variable "db_sku" {
  description = "Flexible Server SKU (tier_name)"
  type        = string
  default     = "GP_Standard_D2s_v3"  # <-- CHANGE THIS: B for dev, GP for prod
}

variable "db_storage_mb" {
  type    = number
  default = 32768                      # 32 GB  # <-- CHANGE THIS
}

variable "db_version" {
  type    = string
  default = "16"                       # <-- CHANGE THIS
}

variable "backup_retention_days" {
  description = "Backup retention period in days (7–35)"
  type        = number
  default     = 14                     # <-- CHANGE THIS
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backup (required for cross-region restore)"
  type        = bool
  default     = true                   # always true in production
}

variable "dr_location" {
  description = "Secondary Azure region for the geo-replica"
  type        = string
  default     = "westus2"             # <-- CHANGE THIS
}

# ---------------------------------------------
# Private DNS Zone for Flexible Server
# ---------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.project}-${var.environment}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "dns-link-postgres"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
  registration_enabled  = false
}

# ---------------------------------------------
# PostgreSQL Flexible Server (Primary)
# ---------------------------------------------
resource "azurerm_postgresql_flexible_server" "primary" {
  name                = "psql-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  version    = var.db_version
  sku_name   = var.db_sku
  storage_mb = var.db_storage_mb

  # Credentials — store in Key Vault; retrieve with data source or use BYOK
  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_admin.result  # generated below

  # Networking — private access only
  delegated_subnet_id    = azurerm_subnet.db.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  # ── Backup configuration ─────────────────────────────────────────────
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup  # enables cross-region restore
  # ────────────────────────────────────────────────────────────────────

  # High Availability — zone-redundant for production
  high_availability {
    mode                      = "ZoneRedundant"  # <-- CHANGE THIS: SameZone for lower cost
    standby_availability_zone = "2"              # <-- CHANGE THIS
  }

  maintenance_window {
    day_of_week  = 0  # Sunday
    start_hour   = 3  # 03:00 UTC  # <-- CHANGE THIS
    start_minute = 0
  }

  # Enable PgBouncer for connection pooling
  # authentication {
  #   active_directory_auth_enabled = true  # optional: AAD auth
  #   password_auth_enabled         = true
  # }

  tags = merge(local.common_tags, { Component = "database" })

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
  name         = "db-admin-password"
  value        = random_password.db_admin.result
  key_vault_id = azurerm_key_vault.main.id   # references Key Vault from main.tf  # <-- CHANGE THIS

  # Set expiry so secret rotation (azure-keyvault-rotation.tf) triggers
  expiration_date = timeadd(timestamp(), "720h")  # 30 days

  tags = local.common_tags
}

# ---------------------------------------------
# DB Subnet (separate from AKS subnet)
# ---------------------------------------------
resource "azurerm_subnet" "db" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.3.0/24"]  # <-- CHANGE THIS: non-overlapping with AKS subnet

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
# Note: Flexible Server geo-restore creates a new server from backup
#       rather than a live replica — use azurerm_postgresql_flexible_server_virtual_endpoint
#       to abstract the connection endpoint across failover.
# ---------------------------------------------
resource "azurerm_postgresql_flexible_server" "dr_replica" {
  count = var.environment == "prod" ? 1 : 0   # <-- CHANGE THIS

  name                = "psql-${var.project}-${var.environment}-dr"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.dr_location

  # Geo-restore: source from the primary's latest backup
  create_mode               = "GeoRestore"
  source_server_id          = azurerm_postgresql_flexible_server.primary.id
  point_in_time_restore_time_in_utc = null  # null = latest available backup

  version    = var.db_version
  sku_name   = var.db_sku
  storage_mb = var.db_storage_mb

  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_admin.result

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false  # DR replica doesn't need geo-backup

  tags = merge(local.common_tags, { Component = "database", Role = "dr-replica" })
}

# ---------------------------------------------
# Azure Monitor Alert — backup failures
# ---------------------------------------------
resource "azurerm_monitor_metric_alert" "db_backup_failed" {
  name                = "alert-db-backup-failed-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_postgresql_flexible_server.primary.id]
  description         = "PostgreSQL Flexible Server backup has failed"
  severity            = 1  # Critical

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "backup_storage_used"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1  # alert if backup storage drops to zero
  }

  window_size        = "PT24H"
  frequency          = "PT6H"

  action {
    action_group_id = var.alert_action_group_id  # <-- CHANGE THIS: pass in your action group
  }

  tags = local.common_tags
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "postgres_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = azurerm_postgresql_flexible_server.primary.fqdn
  sensitive   = true
}

output "db_admin_secret_name" {
  description = "Key Vault secret name for the DB admin password"
  value       = azurerm_key_vault_secret.db_admin_password.name
}

variable "alert_action_group_id" {
  description = "Azure Monitor action group ID for backup failure alerts"
  type        = string
  default     = ""  # <-- CHANGE THIS
}
