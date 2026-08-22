variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cors_allowed_origins" {
  type = list(string)
}

variable "lambda_function_name" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}
