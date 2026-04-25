# ============================================================
# TEMPLATE: Terraform — GCP Cloud SQL Backup & DR Policies
# WHEN TO USE: Add alongside terraform/gcp-gke/main.tf to ensure
#              Cloud SQL (PostgreSQL) has automated backups, PITR,
#              and a cross-region replica configured.
# PREREQUISITES: GCP project with Cloud SQL API enabled (in main.tf).
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: terraform/gcp-gke/main.tf
#                cd/kubernetes/_patterns/velero-backup.yaml
# MATURITY: Stable
# ============================================================

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "db_tier" {
  description = "Cloud SQL machine type"
  type        = string
  default     = "db-custom-2-7680"     # 2 vCPU, 7.5 GB RAM  # <-- CHANGE THIS
}

variable "db_version" {
  type    = string
  default = "POSTGRES_16"              # <-- CHANGE THIS: POSTGRES_16 | MYSQL_8_0
}

variable "backup_start_time" {
  description = "HH:MM UTC time for the daily backup window"
  type        = string
  default     = "02:00"               # <-- CHANGE THIS
}

variable "backup_retention_count" {
  description = "Number of automated backups to retain (1–365)"
  type        = number
  default     = 14                    # <-- CHANGE THIS
}

variable "pitr_enabled" {
  description = "Enable Point-In-Time Recovery (requires binary logging / WAL archiving)"
  type        = bool
  default     = true                  # always true in production
}

variable "dr_region" {
  description = "GCP region for the cross-region read replica"
  type        = string
  default     = "us-west1"           # <-- CHANGE THIS
}

# ---------------------------------------------
# Cloud SQL Primary Instance
# ---------------------------------------------
resource "google_sql_database_instance" "primary" {
  name             = "sql-${var.project}-${var.environment}"
  database_version = var.db_version
  region           = var.gcp_region

  deletion_protection = true          # prevents accidental terraform destroy

  settings {
    tier              = var.db_tier
    availability_type = "REGIONAL"    # multi-zone HA; use ZONAL for dev  # <-- CHANGE THIS

    disk_autoresize       = true
    disk_autoresize_limit = 500       # GB cap  # <-- CHANGE THIS
    disk_size             = 20        # initial GB
    disk_type             = "PD_SSD"

    # ── Backup configuration ────────────────────────────────────────────
    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.pitr_enabled   # WAL archiving for PITR
      transaction_log_retention_days = 7                  # days to keep WAL logs  # <-- CHANGE THIS

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }
    # ────────────────────────────────────────────────────────────────────

    maintenance_window {
      day          = 7   # Sunday
      hour         = 3   # 03:00 UTC  # <-- CHANGE THIS
      update_track = "stable"
    }

    # Private IP only — no public IP
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.main.id  # from main.tf
      enable_private_path_for_google_cloud_services = true
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"  # log queries > 1s  # <-- CHANGE THIS
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = false  # privacy: don't log client IPs
    }
  }

  depends_on = [google_service_networking_connection.private_vpc]
}

# ---------------------------------------------
# Private services connection (VPC peering for Cloud SQL)
# ---------------------------------------------
resource "google_compute_global_address" "private_services" {
  name          = "sql-private-ip-${var.project}-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# ---------------------------------------------
# Cloud SQL Database + User
# ---------------------------------------------
resource "google_sql_database" "app" {
  name     = var.project       # <-- CHANGE THIS
  instance = google_sql_database_instance.primary.name
}

resource "random_password" "db_user" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "google_sql_user" "app" {
  name     = "${var.project}_user"   # <-- CHANGE THIS
  instance = google_sql_database_instance.primary.name
  password = random_password.db_user.result
}

# Store password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project}-${var.environment}-db-password"
  project   = var.gcp_project_id

  replication {
    auto {}  # Google manages cross-region replication automatically
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_user.result
}

# ---------------------------------------------
# Cross-region Read Replica (DR target)
# Promote manually during DR:
#   gcloud sql instances promote-replica sql-<project>-<env>-dr
# ---------------------------------------------
resource "google_sql_database_instance" "dr_replica" {
  count = var.environment == "prod" ? 1 : 0   # <-- CHANGE THIS

  name                 = "sql-${var.project}-${var.environment}-dr"
  database_version     = var.db_version
  region               = var.dr_region
  master_instance_name = google_sql_database_instance.primary.name

  deletion_protection = true

  replica_configuration {
    failover_target = false  # set true to enable auto-failover (Cloud SQL HA)
  }

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL"   # replica doesn't need HA — primary is the SLA boundary

    disk_autoresize       = true
    disk_autoresize_limit = 500
    disk_type             = "PD_SSD"

    # Replica inherits backup settings from primary, but set explicitly for clarity
    backup_configuration {
      enabled    = false   # do not back up the replica — restore from primary backups
      start_time = var.backup_start_time
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
  }
}

# ---------------------------------------------
# Cloud Monitoring Alert — backup failures
# Fires if no backup has succeeded in the last 26 hours
# ---------------------------------------------
resource "google_monitoring_alert_policy" "sql_backup_failed" {
  display_name = "Cloud SQL backup not running — ${var.project}-${var.environment}"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "No successful backup in 26h"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/disk/bytes_used_by_data_type\" AND metric.labels.data_type=\"data\""
      duration        = "0s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      aggregations {
        alignment_period   = "93600s"  # 26 hours
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = []  # <-- CHANGE THIS: add your notification channel IDs
  severity              = "CRITICAL"

  alert_strategy {
    auto_close = "604800s"  # auto-close after 7 days if not acknowledged
  }
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (use with Cloud SQL Proxy)"
  value       = google_sql_database_instance.primary.connection_name
}

output "db_private_ip" {
  description = "Private IP of the Cloud SQL primary instance"
  value       = google_sql_database_instance.primary.private_ip_address
  sensitive   = true
}

output "db_password_secret_id" {
  description = "Secret Manager secret ID for the application DB user password"
  value       = google_secret_manager_secret.db_password.secret_id
}
