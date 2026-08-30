# ---------------------------------------------
# VPC Network + Subnet
# ---------------------------------------------
resource "google_compute_network" "main" {
  name                    = "vpc-${var.project}-${var.environment}"
  auto_create_subnetworks = false

  depends_on = [var.apis_ready]
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
  name   = "nat-${var.project}-${var.environment}"
  router = google_compute_router.main.name
  region = var.gcp_region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
