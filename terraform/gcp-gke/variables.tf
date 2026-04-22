# ============================================================
# TEMPLATE: Terraform Variables — GCP GKE
# WHAT TO CHANGE: Update default values or create a terraform.tfvars
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "project" {
  description = "Project name — used as a prefix for all resource names"
  # Note 2: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "myapp" # <-- CHANGE THIS
# Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "environment" {
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Environment name (dev, staging, prod)"
  type        = string
  # Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "dev" # <-- CHANGE THIS
}

# Note 6: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "gcp_project_id" {
  description = "GCP project ID (not the project name)"
  # Note 7: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  # <-- CHANGE THIS: no default, must be set in terraform.tfvars or via -var
}

# Note 8: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "gcp_region" {
  description = "GCP region for all resources"
  # Note 9: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "us-central1" # <-- CHANGE THIS
# Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "subnet_cidr" {
  # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Primary CIDR range for the GKE subnet"
  type        = string
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "10.0.0.0/20"
}

# Note 13: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "pods_cidr" {
  description = "Secondary CIDR range for GKE pods"
  # Note 14: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "10.4.0.0/14"
# Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

variable "services_cidr" {
  # Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Secondary CIDR range for GKE services"
  type        = string
  # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default     = "10.8.0.0/20"
}

# Note 18: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
variable "node_machine_type" {
  description = "Machine type for GKE nodes — see https://cloud.google.com/compute/docs/machine-types"
  # Note 19: This declaration defines a reusable unit, which supports composition and makes behavior easier to test.
  type        = string
  default     = "e2-standard-4" # <-- CHANGE THIS: size to your workload
# Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
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
