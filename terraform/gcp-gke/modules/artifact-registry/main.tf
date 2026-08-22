# ---------------------------------------------
# Artifact Registry (container images)
# ---------------------------------------------
resource "google_artifact_registry_repository" "main" {
  repository_id = "${var.project}-${var.environment}"
  location      = var.gcp_region
  format        = "DOCKER"
  description   = "Docker repository for ${var.project} ${var.environment}"

  labels = var.common_labels

  depends_on = [var.apis_ready]
}
