output "rds_endpoint" {
  value     = aws_db_instance.primary.endpoint
  sensitive = true
}

output "rds_master_secret_arn" {
  value = aws_db_instance.primary.master_user_secret[0].secret_arn
}
