# ============================================================
# TEMPLATE: Terraform — Google Kubernetes Engine (GKE)
# WHEN TO USE: Provisioning a production-ready GKE cluster on GCP
# PREREQUISITES: GCP project, gcloud CLI authenticated
# SECRETS NEEDED: None (uses gcloud auth or service account key)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/gcp-gke/, cd/kubernetes/
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
      version = "~> 7.30.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Uncomment and configure for remote state
  # backend "gcs" {
  #   bucket = "my-terraform-state"
  #   prefix = "gke/terraform.tfstate"
  # }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "google" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  project = var.gcp_project_id
  region  = var.gcp_region
# Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Enable Required APIs
# ---------------------------------------------
resource "google_project_service" "apis" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  for_each = toset([
    "container.googleapis.com",
    # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  ])

  project = var.gcp_project_id
  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  service = each.value

  disable_on_destroy = false
# Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# VPC Network + Subnet
# ---------------------------------------------
resource "google_compute_network" "main" {
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name                    = "vpc-${var.project}-${var.environment}"
  auto_create_subnetworks = false

  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  depends_on = [google_project_service.apis]
}

# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "google_compute_subnetwork" "gke" {
  name          = "snet-gke-${var.project}-${var.environment}"
  # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  network       = google_compute_network.main.id
  ip_cidr_range = var.subnet_cidr
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  region        = var.gcp_region

  # Secondary ranges for GKE pods and services
  secondary_ip_range {
    # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  secondary_ip_range {
    # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  private_ip_google_access = true
# Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# NAT Router (allows private nodes to reach the internet)
resource "google_compute_router" "main" {
  # Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name    = "router-${var.project}-${var.environment}"
  network = google_compute_network.main.id
  # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  region  = var.gcp_region
}

# Note 26: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "google_compute_router_nat" "main" {
  name                               = "nat-${var.project}-${var.environment}"
  # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
# Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Artifact Registry (container images)
# ---------------------------------------------
resource "google_artifact_registry_repository" "main" {
  # Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  repository_id = "${var.project}-${var.environment}"
  location      = var.gcp_region
  # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  format        = "DOCKER"
  description   = "Docker repository for ${var.project} ${var.environment}"

  # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  labels = local.common_labels

  depends_on = [google_project_service.apis]
# Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# GKE Cluster
# ---------------------------------------------
resource "google_container_cluster" "main" {
  # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name     = "gke-${var.project}-${var.environment}"
  location = var.gcp_region

  # Use a separately managed node pool (recommended)
  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke.id

  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    services_secondary_range_name = "services"
  }

  # Private cluster — nodes have no public IPs
  # Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  private_cluster_config {
    enable_private_nodes    = true
    # Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    enable_private_endpoint = false # <-- CHANGE THIS: set to true for fully private clusters
    master_ipv4_cidr_block  = "172.16.0.0/28"
  # Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  # Workload Identity (recommended over node service accounts)
  workload_identity_config {
    # Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Logging and monitoring
  # Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  # Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  monitoring_config {
    # Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      # Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      enabled = true
    }
  # Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  # Release channel for automatic upgrades
  release_channel {
    # Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    channel = "REGULAR" # Options: RAPID, REGULAR, STABLE
  }

  # Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  resource_labels = local.common_labels

  depends_on = [google_project_service.apis]
# Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# GKE Node Pool
# ---------------------------------------------
resource "google_container_node_pool" "primary" {
  # Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name     = "np-primary-${var.project}-${var.environment}"
  cluster  = google_container_cluster.main.id
  # Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location = var.gcp_region

  node_count = var.enable_autoscaling ? null : var.node_count

  # Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    # Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    content {
      min_node_count = var.node_min_count
      # Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      max_node_count = var.node_max_count
    }
  # Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  node_config {
    # Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    machine_type = var.node_machine_type
    disk_size_gb = 100
    # Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    disk_type    = "pd-standard"

    oauth_scopes = [
      # Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Use Workload Identity instead of node service account
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = local.common_labels

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# ---------------------------------------------
# IAM — Grant GKE access to Artifact Registry
# ---------------------------------------------
resource "google_project_iam_member" "gke_ar_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_container_cluster.main.node_config[0].service_account}"

  depends_on = [google_container_cluster.main]
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  common_labels = {
    project     = var.project
    environment = var.environment
    managed-by  = "terraform"
  }
}
