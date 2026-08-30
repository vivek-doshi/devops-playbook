variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "node_machine_type" {
  type = string
}

variable "node_count" {
  type = number
}

variable "enable_autoscaling" {
  type = bool
}

variable "node_min_count" {
  type = number
}

variable "node_max_count" {
  type = number
}

variable "common_labels" {
  type = map(string)
}

variable "apis_ready" {
  type = list(string)
}
