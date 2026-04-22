# ============================================================
# TEMPLATE: Terraform Outputs — AWS EKS
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "cluster_name" {
  description = "Name of the EKS cluster"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_eks_cluster.main.name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_eks_cluster.main.endpoint
}

# Note 5: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster"
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
# Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

output "kubeconfig_command" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "AWS CLI command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

output "ecr_repository_url" {
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "ECR repository URL — use this as your image registry"
  value       = aws_ecr_repository.main.repository_url
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where EKS nodes run)"
  value       = aws_subnet.private[*].id
}
