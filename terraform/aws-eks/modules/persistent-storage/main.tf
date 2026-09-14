# ============================================================
# TEMPLATE: Terraform — AWS EKS Persistent Storage
# WHEN TO USE: Add alongside terraform/aws-eks/ to ensure EKS workloads have
#              persistent storage (EBS volumes, EFS, or S3) configured
#              before an incident forces your hand.
# WHAT to CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: docs/guides/eks-persistent-storage.md
# MATURITY: Stable
# ============================================================

locals {
  name_prefix  = "${var.project}-${var.environment}"
  storage_tags = merge(var.common_tags, { Component = "persistent-storage" })
}

# ---------------------------------------------
# EBS Volumes (if using EBS)
# ---------------------------------------------
resource "aws_ebs_volume" "main" {
  count                = var.enable_persistent_storage && var.storage_type == "ebs" ? 1 : 0
  availability_zone    = var.availability_zones[0]
  size                 = var.storage_size
  iops                 = var.storage_iops
  throughput           = var.storage_throughput
  type                 = var.storage_volume_type
  multi_attach_enabled = var.storage_multi_attached

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.storage_tags, { Name = "ebs-${local.name_prefix}-${var.storage_class_name}" })
}

# ---------------------------------------------
# EFS File System (if using EFS)
# ---------------------------------------------
resource "aws_efs_file_system" "main" {
  count            = var.enable_persistent_storage && var.storage_type == "efs" ? 1 : 0
  performance_mode = var.storage_performance_mode
  throughput_mode  = var.storage_throughput_mode
  encrypted        = var.storage_encryption

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.storage_tags, { Name = "efs-${local.name_prefix}" })
}

# ---------------------------------------------
# S3 Bucket (if using S3)
# ---------------------------------------------
resource "aws_s3_bucket" "main" {
  count         = var.enable_persistent_storage && var.storage_type == "s3" ? 1 : 0
  bucket        = "s3-${local.name_prefix}-${var.storage_class_name}"
  force_destroy = var.storage_force_destroy

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# Outputs are defined in outputs.tf
