variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "role_arn" {
  type = string
}

variable "role_policy_attachment_id" {
  description = "Forces this module to wait until the IAM policy is attached to the role"
  type        = string
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

variable "timeout" {
  type = number
}

variable "memory_size" {
  type = number
}

variable "lambda_zip_path" {
  type = string
}
