# ---------------------------------------------
# CloudWatch Log Group + Lambda Function
# ---------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}"
  retention_in_days = 30
}

resource "aws_lambda_function" "main" {
  function_name = "${var.project}-${var.environment}"
  role          = var.role_arn
  handler       = var.handler # <-- CHANGE THIS: e.g., "app.handler" for Python, "index.handler" for Node
  runtime       = var.runtime # <-- CHANGE THIS: e.g., "python3.12", "nodejs20.x"
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Option 1: Deploy from a zip file (for initial setup — CI/CD updates this later)
  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  # Option 2: Deploy from a container image (uncomment and remove filename/handler/runtime above)
  # package_type = "Image"
  # image_uri    = "${var.ecr_repository_url}:latest"

  environment {
    variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.environment == "prod" ? "INFO" : "DEBUG"
      # <-- CHANGE THIS: add your application environment variables
    }
  }

  tracing_config {
    mode = "Active" # Enable AWS X-Ray tracing
  }

  depends_on = [
    var.role_policy_attachment_id,
    aws_cloudwatch_log_group.lambda,
  ]
}
