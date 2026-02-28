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
