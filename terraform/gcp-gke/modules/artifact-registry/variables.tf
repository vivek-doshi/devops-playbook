variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "common_labels" {
  type = map(string)
}

variable "apis_ready" {
  type = list(string)
}
