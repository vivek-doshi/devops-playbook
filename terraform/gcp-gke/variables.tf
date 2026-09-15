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

# ---------------------------------------------
# Persistent Storage (modules/persistent-storage)
# ---------------------------------------------
variable "enable_persistent_storage" {
  description = "Enable persistent storage for GKE workloads"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to enable

  validation {
    condition     = can(var.enable_persistent_storage ? true : false)
    error_message = "enable_persistent_storage must be a boolean."
  }
}

variable "storage_type" {
  description = "Type of persistent storage to provision"
  type        = string
  default     = "persistent-disk" # <-- CHANGE THIS: persistent-disk, cloud-storage, or memorystore

  validation {
    condition     = contains(["persistent-disk", "cloud-storage", "memorystore"], var.storage_type)
    error_message = "storage_type must be one of: persistent-disk, cloud-storage, or memorystore."
  }
}

variable "storage_class_name" {
  description = "Name of the storage class (for Persistent Disk)"
  type        = string
  default     = "standard" # <-- CHANGE THIS: standard, premium, or ultra

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_class_name))
    error_message = "storage_class_name must contain only lowercase letters and numbers."
  }
}

variable "storage_size" {
  description = "Size of the Persistent Disk in GB (if using Persistent Disk)"
  type        = number
  default     = 100 # <-- CHANGE THIS: size to your workload

  validation {
    condition     = var.storage_size > 0
    error_message = "storage_size must be greater than 0."
  }
}

variable "storage_disk_type" {
  description = "Disk type for Persistent Disk (if using Persistent Disk)"
  type        = string
  default     = "pd-balanced" # <-- CHANGE THIS: pd-balanced, pd-ssd, pd-hdd, or pd-ultra

  validation {
    condition     = contains(["pd-balanced", "pd-ssd", "pd-hdd", "pd-ultra"], var.storage_disk_type)
    error_message = "storage_disk_type must be one of: pd-balanced, pd-ssd, pd-hdd, or pd-ultra."
  }
}

variable "storage_zone" {
  description = "Zone for the Persistent Disk (if using Persistent Disk)"
  type        = string
  default     = "us-central1-a" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.storage_zone))
    error_message = "storage_zone must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "storage_location" {
  description = "Location for Cloud Storage bucket (if using Cloud Storage)"
  type        = string
  default     = "us-central1" # <-- CHANGE THIS: match your region

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.storage_location))
    error_message = "storage_location must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "storage_tier" {
  description = "Tier for Memorystore cluster (if using Memorystore)"
  type        = string
  default     = "PREMIUM" # <-- CHANGE THIS: PREMIUM or STANDARD

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.storage_tier)
    error_message = "storage_tier must be one of: PREMIUM or STANDARD."
  }
}

variable "storage_node_count" {
  description = "Node count for Memorystore cluster (if using Memorystore)"
  type        = number
  default     = 3 # <-- CHANGE THIS: adjust for your workload

  validation {
    condition     = var.storage_node_count > 0
    error_message = "storage_node_count must be greater than 0."
  }
}

variable "storage_node_memory_gb" {
  description = "Memory per node in GB for Memorystore cluster (if using Memorystore)"
  type        = number
  default     = 512 # <-- CHANGE THIS: adjust for your workload

  validation {
    condition     = var.storage_node_memory_gb > 0
    error_message = "storage_node_memory_gb must be greater than 0."
  }
}

variable "storage_automatic_failover" {
  description = "Enable automatic failover for Memorystore cluster (if using Memorystore)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_automatic_failover ? true : false)
    error_message = "storage_automatic_failover must be a boolean."
  }
}

variable "storage_force_destroy" {
  description = "Force destroy Cloud Storage bucket on deletion (if using Cloud Storage)"
  type        = bool
  default     = false # <-- CHANGE THIS: set to true to force destroy

  validation {
    condition     = can(var.storage_force_destroy ? true : false)
    error_message = "storage_force_destroy must be a boolean."
  }
}

variable "storage_uniform_access" {
  description = "Enable uniform bucket level access for Cloud Storage bucket (if using Cloud Storage)"
  type        = bool
  default     = true # <-- CHANGE THIS: set to false to disable

  validation {
    condition     = can(var.storage_uniform_access ? true : false)
    error_message = "storage_uniform_access must be a boolean."
  }
}

variable "storage_labels" {
  description = "Additional labels to apply to Persistent Disk (if using Persistent Disk)"
  type        = map(string)
  default = {
    workload    = "gke"
    environment = "dev" # <-- CHANGE THIS: match your environment
  }
}
