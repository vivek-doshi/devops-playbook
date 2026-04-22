# ============================================================
# TEMPLATE: Terraform Outputs — AWS Lambda
# ============================================================

# Note 1: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "function_name" {
  description = "Name of the Lambda function"
  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_lambda_function.main.function_name
}

# Note 3: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "function_arn" {
  description = "ARN of the Lambda function"
  # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_lambda_function.main.arn
}

# Note 5: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "api_gateway_url" {
  description = "API Gateway invocation URL — this is your public endpoint"
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_apigatewayv2_api.main.api_endpoint
}

# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "api_gateway_id" {
  description = "API Gateway ID"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  value       = aws_apigatewayv2_api.main.id
}

# Note 9: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda — view logs here"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_role_arn" {
  description = "IAM role ARN assigned to the Lambda function — attach additional policies here"
  value       = aws_iam_role.lambda.arn
}
