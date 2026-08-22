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

variable "db_tier" {
  type = string
}

variable "db_version" {
  type = string
}

variable "backup_start_time" {
  type = string
}

variable "backup_retention_count" {
  type = number
}

variable "pitr_enabled" {
  type = bool
}

variable "dr_region" {
  type = string
}
