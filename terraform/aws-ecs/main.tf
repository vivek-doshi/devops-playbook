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
}

module "ecr" {
  count  = var.enable_ecr ? 1 : 0
  source = "./modules/ecr"

  project     = var.project
  environment = var.environment
}

module "security_groups" {
  count  = var.enable_security_groups ? 1 : 0
  source = "./modules/security-groups"

  project        = var.project
  environment    = var.environment
  vpc_id         = try(module.network[0].vpc_id, null)
  container_port = var.container_port
}

module "alb" {
  count  = var.enable_alb ? 1 : 0
  source = "./modules/alb"

  project               = var.project
  environment           = var.environment
  vpc_id                = try(module.network[0].vpc_id, null)
  public_subnet_ids     = try(module.network[0].public_subnet_ids, [])
  alb_security_group_id = try(module.security_groups[0].alb_security_group_id, null)
  container_port        = var.container_port
}

module "ecs" {
  count  = var.enable_ecs ? 1 : 0
  source = "./modules/ecs"

  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  ecr_repository_url    = try(module.ecr[0].repository_url, "")
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
  private_subnet_ids    = try(module.network[0].private_subnet_ids, [])
  ecs_security_group_id = try(module.security_groups[0].ecs_security_group_id, null)
  target_group_arn      = try(module.alb[0].target_group_arn, null)
  alb_listener_arn      = try(module.alb[0].listener_arn, null)
}

module "autoscaling" {
  count  = var.enable_autoscaling ? 1 : 0
  source = "./modules/autoscaling"

  cluster_name = try(module.ecs[0].cluster_name, null)
  service_name = try(module.ecs[0].service_name, null)
  min_count    = var.min_count
  max_count    = var.max_count
}
