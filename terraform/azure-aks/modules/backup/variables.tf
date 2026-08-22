variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "db_admin_username" {
  type = string
}

variable "db_sku" {
  type = string
}

variable "db_storage_mb" {
  type = number
}

variable "db_version" {
  type = string
}

variable "backup_retention_days" {
  type = number
}

variable "geo_redundant_backup" {
  type = bool
}

variable "dr_location" {
  type = string
}

variable "key_vault_id" {
  type     = string
  default  = null
  nullable = true
}

variable "alert_action_group_id" {
  type    = string
  default = ""
}
