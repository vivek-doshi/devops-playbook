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

variable "os_type" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
