# ============================================================
# TEMPLATE: Terraform Variables — GCP GKE
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

variable "project" {
  description = "Project name — used as a prefix for all resource names"
  type        = string
  default     = "myapp" # <-- CHANGE THIS
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev" # <-- CHANGE THIS
}

variable "gcp_project_id" {
  description = "GCP project ID (not the project name)"
  type        = string
  # <-- CHANGE THIS: no default, must be set in terraform.tfvars or via -var
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
  default     = "us-central1" # <-- CHANGE THIS
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the GKE subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR range for GKE pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_cidr" {
  description = "Secondary CIDR range for GKE services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes — see https://cloud.google.com/compute/docs/machine-types"
  type        = string
  default     = "e2-standard-4" # <-- CHANGE THIS: size to your workload
}

variable "node_count" {
  description = "Number of nodes per zone (ignored if autoscaling is enabled)"
  type        = number
  default     = 1
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaler on the primary node pool"
  type        = bool
  default     = true
}

variable "node_min_count" {
  description = "Minimum node count per zone when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum node count per zone when autoscaling is enabled"
  type        = number
  default     = 5
}

# ---------------------------------------------
# Feature toggles — used only by the orchestrator (main.tf) to select
# which modules to run. Disabling "network" breaks dependent modules
# unless you also disable everything that depends on it.
# ---------------------------------------------
variable "enable_network" {
  description = "Provision the VPC network, subnet, and NAT (core dependency for other modules)"
  type        = bool
  default     = true
}

variable "enable_artifact_registry" {
  description = "Provision the Artifact Registry Docker repository"
  type        = bool
  default     = true
}

variable "enable_gke" {
  description = "Provision the GKE cluster and node pool"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Provision the Cloud SQL backup/DR stack (modules/backup)"
  type        = bool
  default     = false
}

# ---------------------------------------------
# Backup / DR (modules/backup) — only used when enable_backup = true
# ---------------------------------------------
variable "db_tier" {
  description = "Cloud SQL machine type"
  type        = string
  default     = "db-custom-2-7680" # 2 vCPU, 7.5 GB RAM  # <-- CHANGE THIS
}

variable "db_version" {
  type    = string
  default = "POSTGRES_16" # <-- CHANGE THIS: POSTGRES_16 | MYSQL_8_0
}

variable "backup_start_time" {
  description = "HH:MM UTC time for the daily backup window"
  type        = string
  default     = "02:00" # <-- CHANGE THIS
}

variable "backup_retention_count" {
  description = "Number of automated backups to retain (1-365)"
  type        = number
  default     = 14 # <-- CHANGE THIS
}

variable "pitr_enabled" {
  description = "Enable Point-In-Time Recovery (requires binary logging / WAL archiving)"
  type        = bool
  default     = true # always true in production
}

variable "dr_region" {
  description = "GCP region for the cross-region read replica"
  type        = string
  default     = "us-west1" # <-- CHANGE THIS
}
