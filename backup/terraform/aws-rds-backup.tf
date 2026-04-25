# ============================================================
# TEMPLATE: AWS RDS Automated Backups + Cross-Region Replica
# WHEN TO USE: Add to your existing Terraform module that creates an
#   RDS instance. Enables automated point-in-time recovery (PITR) and
#   optionally creates a read replica in a secondary region for DR.
#
# WHAT TO CHANGE: Variables at the top. Integrate into your existing
#   Terraform module — do not apply standalone.
# RELATED FILES: terraform/aws-ecs/, terraform/aws-eks/
# MATURITY: Stable
# ============================================================

# ── Variables ────────────────────────────────────────────────
variable "project" {}
variable "environment" {}
variable "aws_region" { default = "us-east-1" }                    # <-- CHANGE THIS
variable "dr_region" { default = "us-west-2" }                     # <-- CHANGE THIS: secondary region for DR
variable "db_instance_class" { default = "db.t3.medium" }          # <-- CHANGE THIS
variable "db_engine_version" { default = "15.4" }                  # <-- CHANGE THIS: PostgreSQL version
variable "backup_retention_days" { default = 7 }                   # <-- CHANGE THIS: 1–35 days
variable "enable_cross_region_replica" { default = false }         # <-- CHANGE THIS: set true to create DR replica

# ── RDS Instance with PITR ───────────────────────────────────
resource "aws_db_instance" "main" {
  identifier        = "rds-${var.project}-${var.environment}"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = 100           # <-- CHANGE THIS (GiB)
  storage_encrypted = true

  # Note 1: backup_retention_period > 0 enables automated backups and
  # point-in-time recovery. PITR allows restore to any second within the
  # retention window. Minimum recommended: 7 days.
  backup_retention_period = var.backup_retention_days

  # Note 2: The backup window should be outside your peak traffic hours.
  # Format: hh24:mi-hh24:mi UTC.
  backup_window      = "02:00-03:00"    # <-- CHANGE THIS
  maintenance_window = "sun:04:00-sun:05:00"  # <-- CHANGE THIS

  # Note 3: Multi-AZ creates a synchronous standby replica in a different AZ.
  # Automatic failover happens in 1-2 minutes if the primary fails.
  # Enable for production workloads.
  multi_az = var.environment == "production" ? true : false

  deletion_protection = var.environment == "production" ? true : false
  skip_final_snapshot = var.environment == "production" ? false : true

  final_snapshot_identifier = var.environment == "production" ? (
    "rds-${var.project}-${var.environment}-final-snapshot"
  ) : null

  db_subnet_group_name   = aws_db_subnet_group.main.name  # <-- CHANGE THIS: reference your subnet group
  vpc_security_group_ids = [aws_security_group.rds.id]    # <-- CHANGE THIS

  tags = {
    Name        = "rds-${var.project}-${var.environment}"
    Project     = var.project
    Environment = var.environment
  }
}

# ── Cross-Region Read Replica for DR ─────────────────────────
# Note 4: This creates a read replica in a secondary region. In a DR event,
# promote the replica with:
#   aws rds promote-read-replica --db-instance-identifier <replica-id> --region <dr_region>
# Promotion takes ~5 minutes. The replica becomes an independent standalone DB.
resource "aws_db_instance" "dr_replica" {
  count    = var.enable_cross_region_replica ? 1 : 0
  provider = aws.dr   # Requires an 'aws' provider alias for the DR region

  identifier             = "rds-${var.project}-${var.environment}-dr"
  replicate_source_db    = aws_db_instance.main.arn
  instance_class         = var.db_instance_class
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  storage_encrypted      = true
  skip_final_snapshot    = false
  deletion_protection    = true

  tags = {
    Name        = "rds-${var.project}-${var.environment}-dr"
    Project     = var.project
    Environment = var.environment
    Role        = "dr-replica"
  }
}

# ── Manual Snapshot for pre-migration backup ─────────────────
# Note 5: Use aws_db_snapshot to trigger a snapshot before a risky migration.
# Uncomment and apply, then comment out again (snapshots are not re-created on every plan).
# resource "aws_db_snapshot" "pre_migration" {
#   db_instance_identifier = aws_db_instance.main.id
#   db_snapshot_identifier = "rds-${var.project}-${var.environment}-pre-migration"
# }
