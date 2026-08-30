# ============================================================
# TEMPLATE: Terraform — Google Kubernetes Engine (GKE)
# WHEN TO USE: Provisioning a production-ready GKE cluster on GCP
# PREREQUISITES: GCP project, gcloud CLI authenticated
# SECRETS NEEDED: None (uses gcloud auth or service account key)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/gcp-gke/, cd/kubernetes/
# MATURITY: Stable
# LAYOUT: versions.tf (providers/APIs), network.tf (VPC/NAT),
#         artifact-registry.tf, gke.tf (cluster/node pool), iam.tf,
#         backup.tf (DR/backup), locals.tf (labels)
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.45.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "gke/terraform.tfstate"
  # }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ---------------------------------------------
# Enable Required APIs
# ---------------------------------------------
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project = var.gcp_project_id
  service = each.value

  disable_on_destroy = false
}
