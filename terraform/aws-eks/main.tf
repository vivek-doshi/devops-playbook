# ============================================================
# ORCHESTRATOR — selects and wires the feature modules below.
# Toggle a feature by setting its `enable_*` variable to false.
# No resources are defined directly in this file — only module calls.
# ============================================================

module "network" {
  count  = var.enable_network ? 1 : 0
  source = "./modules/network"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  cluster_name       = local.cluster_name
}

module "ecr" {
  count  = var.enable_ecr ? 1 : 0
  source = "./modules/ecr"

  project     = var.project
  environment = var.environment
}

module "iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam"

  project     = var.project
  environment = var.environment
}

module "security_groups" {
  count  = var.enable_security_groups ? 1 : 0
  source = "./modules/security-groups"

  project     = var.project
  environment = var.environment
  vpc_id      = try(module.network[0].vpc_id, null)
  vpc_cidr    = var.vpc_cidr
}

module "eks" {
  count  = var.enable_eks ? 1 : 0
  source = "./modules/eks"

  cluster_name                  = local.cluster_name
  kubernetes_version            = var.kubernetes_version
  cluster_role_arn              = try(module.iam[0].cluster_role_arn, null)
  node_role_arn                 = try(module.iam[0].node_role_arn, null)
  cluster_policy_attachment_ids = try(module.iam[0].cluster_policy_attachment_ids, [])
  node_policy_attachment_ids    = try(module.iam[0].node_policy_attachment_ids, [])
  public_subnet_ids             = try(module.network[0].public_subnet_ids, [])
  private_subnet_ids            = try(module.network[0].private_subnet_ids, [])
  cluster_security_group_id     = try(module.security_groups[0].cluster_security_group_id, null)
  node_group_name               = "ng-${var.project}-${var.environment}"
  node_instance_type            = var.node_instance_type
  node_desired_count            = var.node_desired_count
  node_min_count                = var.node_min_count
  node_max_count                = var.node_max_count
  common_tags                   = local.common_tags

  gpu_node_group_enabled = var.gpu_node_group_enabled
  gpu_node_pool_name     = "ng-gpu-${var.project}-${var.environment}"
  gpu_instance_types     = var.gpu_instance_types
  gpu_capacity_type      = var.gpu_capacity_type
  gpu_ami_type           = var.gpu_ami_type
  gpu_disk_size          = var.gpu_disk_size
  gpu_labels             = var.gpu_labels
  gpu_node_taint_enabled = var.gpu_node_taint_enabled
  gpu_desired_count      = var.gpu_desired_count
  gpu_min_count          = var.gpu_min_count
  gpu_max_count          = var.gpu_max_count
}

module "backup" {
  count  = var.enable_backup ? 1 : 0
  source = "./modules/backup"
  providers = {
    aws           = aws
    aws.dr_region = aws.dr_region
  }

  project            = var.project
  environment        = var.environment
  vpc_id             = try(module.network[0].vpc_id, null)
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = try(module.network[0].private_subnet_ids, [])
  common_tags        = local.common_tags

  db_instance_class     = var.db_instance_class
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_name               = var.db_name
  backup_retention_days = var.backup_retention_days
  backup_window         = var.backup_window
  maintenance_window    = var.maintenance_window
  dr_region             = var.dr_region
  snapshot_s3_bucket    = var.snapshot_s3_bucket
}
