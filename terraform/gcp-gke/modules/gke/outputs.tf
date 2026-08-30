output "name" {
  value = google_container_cluster.main.name
}

output "endpoint" {
  value     = google_container_cluster.main.endpoint
  sensitive = true
}

output "node_service_account" {
  value = google_container_cluster.main.node_config[0].service_account
}
