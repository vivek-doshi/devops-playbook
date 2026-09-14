# ============================================================
# TEMPLATE: Terraform Outputs — AWS EKS
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(module.eks[0].cluster_name, null)
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = try(module.eks[0].cluster_certificate_authority_data, null)
  sensitive   = true
}

output "kubeconfig_command" {
  description = "AWS CLI command to update kubeconfig"
  value       = try("aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks[0].cluster_name}", null)
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this as your image registry"
  value       = try(module.ecr[0].repository_url, null)
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = try(module.network[0].vpc_id, null)
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where EKS nodes run)"
  value       = try(module.network[0].private_subnet_ids, [])
}

# ---------------------------------------------
# Persistent Storage Outputs
# ---------------------------------------------
output "storage_class_id" {
  description = "ID of the storage class for EBS"
  value       = try(module.persistent_storage[0].storage_class_id, null)
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = try(module.persistent_storage[0].efs_file_system_id, null)
}

output "ebs_volume_id" {
  description = "ID of the EBS volume"
  value       = try(module.persistent_storage[0].ebs_volume_id, null)
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = try(module.persistent_storage[0].s3_bucket_id, null)
}

output "storage_type" {
  description = "Type of storage configured"
  value       = try(module.persistent_storage[0].storage_type, null)
}
