# ============================================================
# TEMPLATE: Terraform Outputs — AWS ECS Fargate
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_ecs_cluster.main.name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "ecs_service_name" {
  description = "Name of the ECS service"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_ecs_service.main.name
}

# Note 5: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — point your domain here"
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_lb.main.dns_name
}

# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "alb_url" {
  description = "URL to access the application"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = "http://${aws_lb.main.dns_name}"
}

# Note 9: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "ecr_repository_url" {
  description = "ECR repository URL — use this as your image registry"
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_ecr_repository.main.repository_url
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
