# ============================================================
# TEMPLATE: Terraform Outputs — AWS ECS Fargate
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(module.ecs[0].cluster_name, null)
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = try(module.ecs[0].service_name, null)
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — point your domain here"
  value       = try(module.alb[0].dns_name, null)
}

output "alb_url" {
  description = "URL to access the application"
  value       = try("http://${module.alb[0].dns_name}", null)
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this as your image registry"
  value       = try(module.ecr[0].repository_url, null)
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = try(module.ecs[0].task_definition_arn, null)
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = try(module.network[0].vpc_id, null)
}
