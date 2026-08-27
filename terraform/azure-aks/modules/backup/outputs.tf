output "postgres_fqdn" {
  value     = azurerm_postgresql_flexible_server.primary.fqdn
  sensitive = true
}

output "db_admin_secret_name" {
  value = try(azurerm_key_vault_secret.db_admin_password[0].name, null)
}
