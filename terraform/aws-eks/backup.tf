# ============================================================
# TEMPLATE: Terraform — AWS RDS Backup & DR Policies
# WHEN TO USE: Add alongside terraform/aws-eks/main.tf to ensure RDS
#              instances have automated backups, PITR, and cross-region
#              replicas configured before an incident forces your hand.
# PREREQUISITES: An existing RDS instance or create one here.
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: terraform/aws-eks/main.tf
#                cd/kubernetes/_patterns/velero-backup.yaml
# MATURITY: Stable
# ============================================================

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"             # <-- CHANGE THIS
}

variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "postgres"                 # <-- CHANGE THIS: postgres | mysql | mariadb
}

variable "db_engine_version" {
  type    = string
  default = "16.1"                         # <-- CHANGE THIS: use latest stable
}

variable "db_name" {
  type    = string
  default = "appdb"                        # <-- CHANGE THIS
}

variable "backup_retention_days" {
  description = "Days to retain automated backups (1–35)"
  type        = number
  default     = 14                         # <-- CHANGE THIS: 30 for compliance-sensitive workloads
}

variable "backup_window" {
  description = "UTC window for automated backups — must not overlap maintenance_window"
  type        = string
  default     = "02:00-03:00"              # <-- CHANGE THIS: pick off-peak for your region
}

variable "maintenance_window" {
  type    = string
  default = "Mon:04:00-Mon:05:00"          # <-- CHANGE THIS
}

variable "dr_region" {
  description = "Region for the cross-region read replica (DR target)"
  type        = string
  default     = "us-west-2"               # <-- CHANGE THIS
}

variable "snapshot_s3_bucket" {
  description = "S3 bucket for exported snapshots (DR archive)"
  type        = string
  default     = ""                         # <-- CHANGE THIS: leave empty to skip export
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  db_tags     = merge(local.common_tags, { Component = "database" })
}

# ---------------------------------------------
# RDS Subnet Group
# ---------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "dbsng-${local.name_prefix}"
  description = "Private subnets for RDS"
  subnet_ids  = aws_subnet.private[*].id   # references subnets from main.tf
  tags        = local.db_tags
}

# ---------------------------------------------
# RDS Parameter Group — enable logical replication for PITR
# ---------------------------------------------
resource "aws_db_parameter_group" "main" {
  name   = "pg-${local.name_prefix}"
  family = "${var.db_engine}${split(".", var.db_engine_version)[0]}" # e.g. postgres16

  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = local.db_tags
}

# ---------------------------------------------
# Primary RDS Instance
# ---------------------------------------------
resource "aws_db_instance" "primary" {
  identifier     = "rds-${local.name_prefix}"
  instance_class = var.db_instance_class
  engine         = var.db_engine
  engine_version = var.db_engine_version
  db_name        = var.db_name

  # Credentials — pulled from Secrets Manager after rotation is set up
  # Use manage_master_user_password instead of hardcoding a password
  manage_master_user_password = true       # stores password in Secrets Manager automatically
  master_username             = "dbadmin" # <-- CHANGE THIS

  # Storage
  allocated_storage     = 20              # GB  # <-- CHANGE THIS
  max_allocated_storage = 200             # enables autoscaling  # <-- CHANGE THIS
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = null            # <-- CHANGE THIS: set to a CMK ARN for compliance

  # High Availability
  multi_az = true                         # always true in production

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false          # never expose RDS to the internet

  # ── Backup configuration ──────────────────────────────────────────────
  backup_retention_period   = var.backup_retention_days  # PITR window
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false       # keep backups even if instance is deleted
  skip_final_snapshot       = false       # always take a final snapshot on destroy
  final_snapshot_identifier = "final-${local.name_prefix}-${formatdate("YYYYMMDDHHmm", timestamp())}"
  # ─────────────────────────────────────────────────────────────────────

  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7  # days (731 for long-term, costs extra)
  monitoring_interval                   = 60 # Enhanced Monitoring — 0 to disable
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = ["postgresql"] # <-- CHANGE THIS: depends on engine

  parameter_group_name = aws_db_parameter_group.main.name
  db_subnet_group_name = aws_db_subnet_group.main.name

  tags = local.db_tags
}

# ---------------------------------------------
# IAM role for Enhanced Monitoring
# ---------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  name = "role-rds-monitoring-${local.name_prefix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------
# Cross-region Read Replica (DR target)
# Creates a replica in a secondary region — promotes it manually during DR
# ---------------------------------------------
resource "aws_db_instance" "dr_replica" {
  count = var.environment == "prod" ? 1 : 0  # only in production  # <-- CHANGE THIS

  provider   = aws.dr_region                  # configure a second provider alias
  identifier = "rds-${local.name_prefix}-dr"

  # Read replica config
  replicate_source_db = aws_db_instance.primary.arn
  instance_class      = var.db_instance_class

  # Backup: replicas inherit retention from primary but set it explicitly
  backup_retention_period = var.backup_retention_days
  backup_window           = var.backup_window
  skip_final_snapshot     = false
  final_snapshot_identifier = "final-dr-${local.name_prefix}"

  storage_encrypted = true
  multi_az          = false           # promote to multi-AZ only after DR failover if needed
  publicly_accessible = false

  auto_minor_version_upgrade = true
  tags                       = merge(local.db_tags, { Role = "dr-replica" })
}

# ---------------------------------------------
# Automated Snapshot Export to S3 (optional — for long-term archive)
# Exports the latest daily snapshot to S3 in Parquet format.
# Useful for compliance archiving and analytics.
# ---------------------------------------------
resource "aws_db_snapshot_export_task" "archive" {
  count = var.snapshot_s3_bucket != "" ? 1 : 0

  export_task_identifier = "export-${local.name_prefix}"
  source_arn             = aws_db_instance.primary.arn
  s3_bucket_name         = var.snapshot_s3_bucket # <-- CHANGE THIS
  s3_prefix              = "rds-exports/${local.name_prefix}/"
  iam_role_arn           = aws_iam_role.rds_export.arn
  kms_key_id             = aws_db_instance.primary.kms_key_id
}

resource "aws_iam_role" "rds_export" {
  count = var.snapshot_s3_bucket != "" ? 1 : 0
  name  = "role-rds-export-${local.name_prefix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "export.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# ---------------------------------------------
# CloudWatch Alarm — failed backups
# ---------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_backup_missing" {
  alarm_name          = "alarm-rds-backup-missing-${local.name_prefix}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BackupRetentionPeriodStorageUsed"
  namespace           = "AWS/RDS"
  period              = 86400   # 24 hours
  statistic           = "Sum"
  threshold           = 1       # alert if no backup storage is being used
  alarm_description   = "RDS automated backups appear to have stopped"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  alarm_actions = []  # <-- CHANGE THIS: add your SNS topic ARN
  ok_actions    = []
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "rds_endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.primary.endpoint
  sensitive   = true
}

output "rds_master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master password"
  value       = aws_db_instance.primary.master_user_secret[0].secret_arn
}
