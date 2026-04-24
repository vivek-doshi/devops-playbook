# ============================================================
# TEMPLATE: Terraform — GCP Remote State Bootstrap
# WHEN TO USE: Creating the shared GCS backend before other GCP Terraform modules adopt remote state
# PREREQUISITES: GCP project, gcloud CLI authenticated, local state for the first bootstrap apply
# SECRETS NEEDED: None (uses gcloud auth or service account key)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: terraform/gcp-gke/main.tf
# MATURITY: Stable
# ============================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    google = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/google"
      version = "~> 5.10.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "google" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  project = local.gcp_project_id
  region  = local.gcp_region
# Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Enable Required API
# ---------------------------------------------
# Note 8: The Storage API must exist before Terraform can create the shared backend bucket in the target project.
resource "google_project_service" "storage" {
  project = local.gcp_project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

# ---------------------------------------------
# Remote State Bucket
# ---------------------------------------------
# Note 9: A versioned GCS bucket provides durable remote state without requiring extra bootstrap modules or cross-project wiring.
resource "google_storage_bucket" "terraform_state" {
  name          = local.bucket_name # <-- CHANGE THIS: bucket names must be globally unique across GCP
  location      = local.bucket_location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Note 10: Lifecycle expiration removes noncurrent object generations after 90 days to control long-term storage costs.
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                = 90
      with_state         = "ARCHIVED"
      num_newer_versions = 1
    }
  }

  labels = local.common_labels

  depends_on = [google_project_service.storage]
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "bucket_name" {
  description = "GCS bucket name to copy into backend \"gcs\" bucket settings in the dependent Terraform modules."
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_prefix_example" {
  description = "Example backend \"gcs\" prefix to adapt per module, such as gke/terraform.tfstate for the GKE root module."
  value       = "gke/terraform.tfstate"
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  project         = "devops-playbook"             # <-- CHANGE THIS: replace with your organisation or platform project name
  gcp_project_id  = "my-gcp-project"             # <-- CHANGE THIS: set the target project ID that will own shared Terraform state
  gcp_region      = "europe-west1"               # <-- CHANGE THIS: choose the GCP region used by your platform team
  bucket_name     = "devops-playbook-tfstate"    # <-- CHANGE THIS: must be globally unique across all GCP projects
  bucket_location = "EU"                         # <-- CHANGE THIS: use a region or multi-region that matches your compliance needs

  common_labels = {
    project     = local.project
    environment = "shared"
    managed-by  = "terraform"
    purpose     = "terraform-state"
  }
}
