# ============================================================
# TEMPLATE: Azure Database for PostgreSQL Flexible Server — Backups
# WHEN TO USE: Add to your existing Terraform module that creates an
#   Azure PostgreSQL Flexible Server. Enables geo-redundant backups
#   and configures a geo-restore replica for DR.
#
# WHAT TO CHANGE: Variables at the top. Integrate into your existing module.
# RELATED FILES: terraform/azure-aks/, terraform/azure-app-service/
# MATURITY: Stable
# ============================================================

variable "project" {}
variable "environment" {}
variable "location" { default = "eastus" }                 # <-- CHANGE THIS: primary region
variable "dr_location" { default = "westus" }              # <-- CHANGE THIS: secondary region for geo-restore
variable "postgres_sku_name" { default = "GP_Standard_D4s_v3" }   # <-- CHANGE THIS
variable "postgres_version" { default = "15" }             # <-- CHANGE THIS
variable "backup_retention_days" { default = 7 }           # <-- CHANGE THIS: 7–35 days
variable "enable_geo_redundant_backup" { default = true }  # <-- CHANGE THIS: required for geo-restore

# ── PostgreSQL Flexible Server with PITR ─────────────────────
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  version             = var.postgres_version
  sku_name            = var.postgres_sku_name

  # Note 1: geo_redundant_backup_enabled = true replicates backup files to
  # the paired Azure region. This is a prerequisite for geo-restore (RPO ~1h).
  # It cannot be changed after server creation — plan ahead.
  geo_redundant_backup_enabled = var.enable_geo_redundant_backup
  backup_retention_days        = var.backup_retention_days

  # Note 2: zone = "1" combined with standby_availability_zone = "2" enables
  # High Availability with a synchronous hot standby in a different AZ.
  # Automatic failover takes < 120 seconds.
  high_availability {
    mode                      = var.environment == "production" ? "ZoneRedundant" : "Disabled"
    standby_availability_zone = "2"   # <-- CHANGE THIS
  }

  zone = "1"   # <-- CHANGE THIS: primary availability zone

  administrator_login    = "psqladmin"    # <-- CHANGE THIS: admin username
  administrator_password = var.db_admin_password

  storage_mb = 32768   # <-- CHANGE THIS: 32 GiB minimum

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# ── Geo-Restore (DR) ─────────────────────────────────────────
# Note 3: Geo-restore creates a new server from the geo-redundant backup
# in the paired region. This is a MANUAL step — it is not automatic.
#
# To perform geo-restore via az CLI (not Terraform — do this during a DR event):
#   az postgres flexible-server geo-restore \
#     --name psql-<project>-<env>-dr \
#     --resource-group <dr-rg> \
#     --location westus \
#     --source-server /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-<project>-<env> \
#     --geo-redundant-backup Enabled
#
# Geo-restore RPO: ~1 hour (replication lag to paired region)
# Geo-restore RTO: ~30–60 minutes to provision a new server

# ── Point-in-Time Restore ────────────────────────────────────
# Note 4: To restore to a specific point in time (up to backup_retention_days ago):
#   az postgres flexible-server restore \
#     --name psql-<project>-<env>-restored \
#     --resource-group <rg> \
#     --source-server psql-<project>-<env> \
#     --restore-time "2024-01-15T02:00:00Z"
#
# The restored server is independent — no traffic is automatically redirected.
# Update your connection string after validating the restore.
