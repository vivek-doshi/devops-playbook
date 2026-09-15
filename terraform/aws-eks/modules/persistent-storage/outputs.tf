# ============================================================
# TEMPLATE: Terraform Outputs — AWS EKS Persistent Storage
# WHAT TO CHANGE: Update descriptions or add additional outputs
# ============================================================

output "efs_file_system_id" {
  value       = try(aws_efs_file_system.main[0].id)
  description = "ID of the EFS file system"
}

output "ebs_volume_id" {
  value       = try(aws_ebs_volume.main[0].id, null)
  description = "ID of the EBS volume"
}

output "s3_bucket_id" {
  value       = try(aws_s3_bucket.main[0].id, null)
  description = "ID of the S3 bucket"
}

output "storage_type" {
  value       = var.storage_type
  description = "Type of storage configured"
}
