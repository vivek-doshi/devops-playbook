# ---------------------------------------------
# EKS Cluster
# ---------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true # <-- CHANGE THIS: set to false for private clusters
    security_group_ids      = [var.cluster_security_group_id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [var.cluster_policy_attachment_ids]
}

# ---------------------------------------------
# EKS Managed Node Groups
# ---------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [var.node_policy_attachment_ids]
}

resource "aws_eks_node_group" "gpu" {
  count           = var.gpu_node_group_enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.gpu_node_pool_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.gpu_instance_types
  capacity_type   = var.gpu_capacity_type
  ami_type        = var.gpu_ami_type
  disk_size       = var.gpu_disk_size
  labels          = var.gpu_labels

  scaling_config {
    desired_size = var.gpu_desired_count
    min_size     = var.gpu_min_count
    max_size     = var.gpu_max_count
  }

  dynamic "taint" {
    for_each = var.gpu_node_taint_enabled ? [1] : []
    content {
      key    = "nvidia.com/gpu"
      value  = "dedicated"
      effect = "NO_SCHEDULE"
    }
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.common_tags, {
    Name     = var.gpu_node_pool_name
    NodePool = "gpu"
  })

  depends_on = [var.node_policy_attachment_ids]
}
