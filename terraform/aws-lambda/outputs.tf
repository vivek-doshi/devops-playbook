# ============================================================
# TEMPLATE: Terraform Outputs — AWS Lambda
# Values are read from the modules selected by the orchestrator (main.tf).
# ============================================================

output "function_name" {
  description = "Name of the Lambda function"
  value       = try(module.lambda[0].function_name, null)
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = try(module.lambda[0].function_arn, null)
}

output "api_gateway_url" {
  description = "API Gateway invocation URL — this is your public endpoint"
  value       = try(module.api_gateway[0].api_endpoint, null)
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = try(module.api_gateway[0].api_id, null)
}

output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda — view logs here"
  value       = try(module.lambda[0].log_group_name, null)
}

output "lambda_role_arn" {
  description = "IAM role ARN assigned to the Lambda function — attach additional policies here"
  value       = try(module.iam[0].role_arn, null)
}
