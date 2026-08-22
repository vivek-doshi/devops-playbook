variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "pods_cidr" {
  type = string
}

variable "services_cidr" {
  type = string
}

variable "apis_ready" {
  description = "Forces this module to wait until the required GCP APIs are enabled"
  type        = list(string)
}
