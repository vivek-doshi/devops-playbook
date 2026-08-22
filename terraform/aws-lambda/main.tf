# ============================================================
# ORCHESTRATOR — selects and wires the feature modules below.
# Toggle a feature by setting its `enable_*` variable to false.
# No resources are defined directly in this file — only module calls.
# ============================================================

module "iam" {
  count  = var.enable_iam ? 1 : 0
  source = "./modules/iam"

  project     = var.project
  environment = var.environment
}

module "lambda" {
  count  = var.enable_lambda ? 1 : 0
  source = "./modules/lambda"

  project                   = var.project
  environment               = var.environment
  role_arn                  = try(module.iam[0].role_arn, null)
  role_policy_attachment_id = try(module.iam[0].policy_attachment_id, null)
  handler                   = var.handler
  runtime                   = var.runtime
  timeout                   = var.timeout
  memory_size               = var.memory_size
  lambda_zip_path           = var.lambda_zip_path
}

module "api_gateway" {
  count  = var.enable_api_gateway ? 1 : 0
  source = "./modules/api-gateway"

  project              = var.project
  environment          = var.environment
  cors_allowed_origins = var.cors_allowed_origins
  lambda_function_name = try(module.lambda[0].function_name, null)
  lambda_invoke_arn    = try(module.lambda[0].invoke_arn, null)
}
