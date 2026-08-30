# ============================================================
# TEMPLATE: Terraform Outputs — GCP GKE
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = try(module.gke[0].name, null)
}

output "cluster_endpoint" {
  description = "GKE cluster API server endpoint"
  value       = try(module.gke[0].endpoint, null)
  sensitive   = true
}

output "kubeconfig_command" {
  description = "gcloud command to get kubeconfig"
  value       = try("gcloud container clusters get-credentials ${module.gke[0].name} --region ${var.gcp_region} --project ${var.gcp_project_id}", null)
}

output "artifact_registry_url" {
  description = "Artifact Registry repository URL — use as your image registry"
  value       = try("${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${module.artifact_registry[0].repository_id}", null)
}

output "network_name" {
  description = "Name of the VPC network"
  value       = try(module.network[0].network_name, null)
}

output "subnet_name" {
  description = "Name of the GKE subnet"
  value       = try(module.network[0].subnet_name, null)
}
