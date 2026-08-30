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

variable "acr_sku" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
