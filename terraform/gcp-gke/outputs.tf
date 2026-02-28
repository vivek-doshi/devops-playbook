# ============================================================
# TEMPLATE: Terraform Outputs — GCP GKE
# ============================================================

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "GKE cluster API server endpoint"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "kubeconfig_command" {
  description = "gcloud command to get kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL — use as your image registry"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.main.repository_id}"
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke.name
}
