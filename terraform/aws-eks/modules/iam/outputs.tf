output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "node_policy_attachment_ids" {
  value = [
    aws_iam_role_policy_attachment.eks_worker_node_policy.id,
    aws_iam_role_policy_attachment.eks_cni_policy.id,
    aws_iam_role_policy_attachment.ecr_read_only.id,
  ]
}

output "cluster_policy_attachment_ids" {
  value = [
    aws_iam_role_policy_attachment.eks_cluster_policy.id,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller.id,
  ]
}
