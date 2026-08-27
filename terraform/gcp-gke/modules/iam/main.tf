# ---------------------------------------------
# IAM — Grant GKE access to Artifact Registry
# ---------------------------------------------
resource "google_project_iam_member" "gke_ar_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${var.gke_node_service_account}"
}
