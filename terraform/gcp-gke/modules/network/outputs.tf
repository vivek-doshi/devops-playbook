output "network_id" {
  value = google_compute_network.main.id
}

output "network_name" {
  value = google_compute_network.main.name
}

output "subnet_id" {
  value = google_compute_subnetwork.gke.id
}

output "subnet_name" {
  value = google_compute_subnetwork.gke.name
}
