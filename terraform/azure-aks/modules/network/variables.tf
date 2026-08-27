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

variable "vnet_address_space" {
  type = string
}

variable "aks_subnet_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
