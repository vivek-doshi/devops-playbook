# ============================================================
# TEMPLATE: Terraform — AWS EKS Persistent Storage
# WHEN TO USE: Add alongside terraform/aws-eks/ to ensure EKS workloads have
#              persistent storage (EBS volumes, EFS, or S3) configured
#              before an incident forces your hand.
# WHAT TO CHANGE: Lines marked  # <-- CHANGE THIS
# RELATED FILES: docs/guides/eks-persistent-storage.md
# MATURITY: Stable
# ============================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  storage_tags = merge(var.common_tags, { Component = "persistent-storage" })
}

# ---------------------------------------------
# EBS Storage Class (if using EBS)
# ---------------------------------------------
resource "aws_storage_class" "main" {
  count = var.enable_persistent_storage ? 1 : 0
  name = "sc-${local.name_prefix}-ebs"
  type = "Standard"

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# EFS File System (if using EFS)
# ---------------------------------------------
resource "aws_efs_file_system" "main" {
  count = var.enable_persistent_storage && var.storage_type == "efs" ? 1 : 0
  creation_token = aws_storage_class.main[0].creation_token
  creation_token_id = aws_storage_class.main[0].id

  name = "efs-${local.name_prefix}"
  availability_zone = var.availability_zones[0]
  performance_mode = var.storage_performance_mode
  throughput_mode = var.storage_throughput_mode
  encryption = var.storage_encryption

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# EBS Volumes (if using EBS)
# ---------------------------------------------
resource "aws_ebs_volume" "main" {
  count = var.enable_persistent_storage && var.storage_type == "ebs" ? 1 : 0
  name = "ebs-${local.name_prefix}-${var.storage_class_name}"
  size = var.storage_size
  iops = var.storage_iops
  throughput = var.storage_throughput
  volume_type = var.storage_volume_type
  multi_attached = var.storage_multi_attached

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# S3 Bucket (if using S3)
# ---------------------------------------------
resource "aws_s3_bucket" "main" {
  count = var.enable_persistent_storage && var.storage_type == "s3" ? 1 : 0
  bucket = "s3-${local.name_prefix}-${var.storage_class_name}"
  force_destroy = var.storage_force_destroy

  lifecycle {
    create_before_destroy = true
  }

  tags = local.storage_tags
}

# ---------------------------------------------
# Storage Class Output
# ---------------------------------------------
output "storage_class_id" {
  value = try(aws_storage_class.main[0].id, null)
  description = "ID of the storage class for EBS"
}

output "efs_file_system_id" {
  value = try(aws_ebs_file_system.main[0].id, null)
  description = "ID of the EFS file system"
}

output "ebs_volume_id" {
  value = try(aws_ebs_volume.main[0].id, null)
  description = "ID of the EBS volume"
}

output "s3_bucket_id" {
  value = try(aws_s3_bucket.main[0].id, null)
  description = "ID of the S3 bucket"
}

output "storage_type" {
  value = var.storage_type
  description = "Type of storage configured"
}
