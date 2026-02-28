# ============================================================
# TEMPLATE: Terraform Outputs — AWS Lambda
# ============================================================

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "api_gateway_url" {
  description = "API Gateway invocation URL — this is your public endpoint"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda — view logs here"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_role_arn" {
  description = "IAM role ARN assigned to the Lambda function — attach additional policies here"
  value       = aws_iam_role.lambda.arn
}
