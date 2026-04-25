# ============================================================
# TEMPLATE: GCP Cloud SQL — Backups and Cross-Region Replica
# WHEN TO USE: Add to your existing Terraform module that creates a
#   Cloud SQL instance. Enables automated backups, PITR, and optionally
#   creates a cross-region read replica for DR.
#
# WHAT TO CHANGE: Variables at the top. Integrate into your existing module.
# RELATED FILES: terraform/gcp-gke/
# MATURITY: Stable
# ============================================================

variable "project_id" {}                                # <-- CHANGE THIS: GCP project ID
variable "project" {}
variable "environment" {}
variable "region" { default = "us-central1" }           # <-- CHANGE THIS
variable "dr_region" { default = "us-east1" }           # <-- CHANGE THIS: DR region
variable "db_tier" { default = "db-custom-4-15360" }    # <-- CHANGE THIS: 4 vCPU, 15 GB RAM
variable "postgres_version" { default = "POSTGRES_15" } # <-- CHANGE THIS
variable "backup_start_time" { default = "02:00" }      # <-- CHANGE THIS: HH:MM UTC
variable "backup_retained_backups" { default = 7 }      # <-- CHANGE THIS: 1–365
variable "enable_dr_replica" { default = false }        # <-- CHANGE THIS: set true to create cross-region replica

# ── Cloud SQL Instance with PITR ─────────────────────────────
resource "google_sql_database_instance" "main" {
  name             = "sql-${var.project}-${var.environment}"
  project          = var.project_id
  region           = var.region
  database_version = var.postgres_version

  deletion_protection = var.environment == "production" ? true : false

  settings {
    tier              = var.db_tier
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"  # Note 1: REGIONAL = HA with automatic failover

    backup_configuration {
      enabled    = true
      start_time = var.backup_start_time

      # Note 2: point_in_time_recovery_enabled uses transaction logs to allow
      # restore to any second within the retained_backups * 1-day window.
      # Requires binary logging (PostgreSQL: WAL archiving enabled automatically).
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7   # <-- CHANGE THIS

      backup_retention_settings {
        retained_backups = var.backup_retained_backups
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false   # Note 3: Disable public IP — use Cloud SQL Auth Proxy or Private IP
      private_network = google_compute_network.main.id  # <-- CHANGE THIS: reference your VPC
    }

    maintenance_window {
      day          = 7   # Sunday
      hour         = 4   # 04:00 UTC
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      record_application_tags = true
      record_client_address   = false
    }
  }
}

# ── Cross-Region Read Replica for DR ─────────────────────────
# Note 4: Cloud SQL read replicas in a different region serve as the
# DR target. During a DR event, promote the replica:
#   gcloud sql instances promote-replica sql-<project>-<env>-dr --project <project>
# Promotion takes ~5-10 minutes. The replica becomes a standalone primary.
resource "google_sql_database_instance" "dr_replica" {
  count = var.enable_dr_replica ? 1 : 0

  name                 = "sql-${var.project}-${var.environment}-dr"
  project              = var.project_id
  region               = var.dr_region
  database_version     = var.postgres_version
  master_instance_name = google_sql_database_instance.main.name

  deletion_protection = true

  settings {
    tier = var.db_tier

    # Note 5: Read replicas use async replication. Typical lag is < 5 seconds
    # under normal load but can increase during heavy write bursts.
    # Monitor replication lag in Cloud SQL metrics: database/replication/replica_lag.
    backup_configuration {
      enabled = true

      backup_retention_settings {
        retained_backups = var.backup_retained_backups
      }
    }

    ip_configuration {
      ipv4_enabled = false
    }
  }
}
