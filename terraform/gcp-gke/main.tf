# ============================================================
# TEMPLATE: Terraform — Google Kubernetes Engine (GKE)
# WHEN TO USE: Provisioning a production-ready GKE cluster on GCP
# PREREQUISITES: GCP project, gcloud CLI authenticated
# SECRETS NEEDED: None (uses gcloud auth or service account key)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/gcp-gke/, cd/kubernetes/
# MATURITY: Stable
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10.0" # <-- CHANGE THIS: pin to latest stable
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

# ---------------------------------------------
# VPC Network + Subnet
# ---------------------------------------------
resource "google_compute_network" "main" {
  name                    = "vpc-${var.project}-${var.environment}"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "gke" {
  name          = "snet-gke-${var.project}-${var.environment}"
  network       = google_compute_network.main.id
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region

  # Secondary ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = true
}

# NAT Router (allows private nodes to reach the internet)
resource "google_compute_router" "main" {
  name    = "router-${var.project}-${var.environment}"
  network = google_compute_network.main.id
  region  = var.gcp_region
}

resource "google_compute_router_nat" "main" {
  name                               = "nat-${var.project}-${var.environment}"
  router                             = google_compute_router.main.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ---------------------------------------------
# Artifact Registry (container images)
# ---------------------------------------------
resource "google_artifact_registry_repository" "main" {
  repository_id = "${var.project}-${var.environment}"
  location      = var.gcp_region
  format        = "DOCKER"
  description   = "Docker repository for ${var.project} ${var.environment}"

  labels = local.common_labels

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------
# GKE Cluster
# ---------------------------------------------
resource "google_container_cluster" "main" {
  name     = "gke-${var.project}-${var.environment}"
  location = var.gcp_region

  # Use a separately managed node pool (recommended)
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.gke.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Private cluster — nodes have no public IPs
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # <-- CHANGE THIS: set to true for fully private clusters
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Workload Identity (recommended over node service accounts)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  # Release channel for automatic upgrades
  release_channel {
    channel = "REGULAR" # Options: RAPID, REGULAR, STABLE
  }

  resource_labels = local.common_labels

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------
# GKE Node Pool
# ---------------------------------------------
resource "google_container_node_pool" "primary" {
  name     = "np-primary-${var.project}-${var.environment}"
  cluster  = google_container_cluster.main.id
  location = var.gcp_region

  node_count = var.enable_autoscaling ? null : var.node_count

  dynamic "autoscaling" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_node_count = var.node_min_count
      max_node_count = var.node_max_count
    }
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = 100
    disk_type    = "pd-standard"

    oauth_scopes = [
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
