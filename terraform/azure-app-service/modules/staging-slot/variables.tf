variable "app_service_id" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "docker_registry_url" {
  type = string
}

variable "docker_registry_username" {
  type      = string
  sensitive = true
}

variable "docker_registry_password" {
  type      = string
  sensitive = true
}

variable "common_tags" {
  type = map(string)
}
