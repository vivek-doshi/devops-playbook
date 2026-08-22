# ---------------------------------------------
# GKE Cluster
# ---------------------------------------------
resource "google_container_cluster" "main" {
  name     = "gke-${var.project}-${var.environment}"
  location = var.gcp_region

  # Use a separately managed node pool (recommended)
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnet_id

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

  resource_labels = var.common_labels

  depends_on = [var.apis_ready]
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

    labels = var.common_labels

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
