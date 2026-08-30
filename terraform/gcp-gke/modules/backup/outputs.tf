output "connection_name" {
  value = google_sql_database_instance.primary.connection_name
}

output "private_ip" {
  value     = google_sql_database_instance.primary.private_ip_address
  sensitive = true
}

output "password_secret_id" {
  value = google_secret_manager_secret.db_password.secret_id
}
