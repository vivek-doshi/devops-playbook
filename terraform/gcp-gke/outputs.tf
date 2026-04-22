# ============================================================
# TEMPLATE: Terraform Outputs — GCP GKE
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "cluster_name" {
  description = "Name of the GKE cluster"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = google_container_cluster.main.name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "cluster_endpoint" {
  description = "GKE cluster API server endpoint"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = google_container_cluster.main.endpoint
  sensitive   = true
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

output "kubeconfig_command" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "gcloud command to get kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
# Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

output "artifact_registry_url" {
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  description = "Artifact Registry repository URL — use as your image registry"
  value       = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.main.repository_id}"
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke.name
}
