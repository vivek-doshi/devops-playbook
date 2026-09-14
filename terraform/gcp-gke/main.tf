# ============================================================
# ORCHESTRATOR — selects and wires the feature modules below.
# Toggle a feature by setting its `enable_*` variable to false.
# No resources are defined directly in this file — only module calls.
# ============================================================

module "network" {
  count  = var.enable_network ? 1 : 0
  source = "./modules/network"

  project       = var.project
  environment   = var.environment
  gcp_region    = var.gcp_region
  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr
  apis_ready    = [for s in google_project_service.apis : s.id]
}

module "artifact_registry" {
  count  = var.enable_artifact_registry ? 1 : 0
  source = "./modules/artifact-registry"

  project       = var.project
  environment   = var.environment
  gcp_region    = var.gcp_region
  common_labels = local.common_labels
  apis_ready    = [for s in google_project_service.apis : s.id]
}

module "gke" {
  count  = var.enable_gke ? 1 : 0
  source = "./modules/gke"

  project            = var.project
  environment        = var.environment
  gcp_project_id     = var.gcp_project_id
  gcp_region         = var.gcp_region
  network_id         = try(module.network[0].network_id, null)
  subnet_id          = try(module.network[0].subnet_id, null)
  node_machine_type  = var.node_machine_type
  node_count         = var.node_count
  enable_autoscaling = var.enable_autoscaling
  node_min_count     = var.node_min_count
  node_max_count     = var.node_max_count
  common_labels      = local.common_labels
  apis_ready         = [for s in google_project_service.apis : s.id]
}

module "iam" {
  count  = var.enable_gke && var.enable_artifact_registry ? 1 : 0
  source = "./modules/iam"

  gcp_project_id           = var.gcp_project_id
  gke_node_service_account = try(module.gke[0].node_service_account, null)
}

module "backup" {
  count  = var.enable_backup ? 1 : 0
  source = "./modules/backup"

  project        = var.project
  environment    = var.environment
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  network_id     = try(module.network[0].network_id, null)

  db_tier                = var.db_tier
  db_version             = var.db_version
  backup_start_time      = var.backup_start_time
  backup_retention_count = var.backup_retention_count
  pitr_enabled           = var.pitr_enabled
  dr_region              = var.dr_region
}

module "persistent_storage" {
  count  = var.enable_persistent_storage ? 1 : 0
  source = "./modules/persistent-storage"

  project            = var.project
  environment        = var.environment
  gcp_project_id     = var.gcp_project_id
  gcp_region         = var.gcp_region
  network_id         = try(module.network[0].network_id, null)
  common_labels      = local.common_labels

  storage_type            = var.storage_type
  storage_class_name      = var.storage_class_name
  storage_size            = var.storage_size
  storage_disk_type      = var.storage_disk_type
  storage_zone            = var.storage_zone
  storage_location        = var.storage_location
  storage_tier            = var.storage_tier
  storage_node_count      = var.storage_node_count
  storage_node_memory_gb  = var.storage_node_memory_gb
  storage_automatic_failover = var.storage_automatic_failover
  storage_force_destroy   = var.storage_force_destroy
  storage_uniform_access  = var.storage_uniform_access
  storage_labels          = var.storage_labels
}
