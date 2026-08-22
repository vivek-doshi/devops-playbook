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

variable "kubernetes_version" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_vm_size" {
  type = string
}

variable "aks_subnet_id" {
  type = string
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

variable "log_analytics_workspace_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "gpu_node_pool_enabled" {
  type = bool
}

variable "gpu_node_pool_name" {
  type = string
}

variable "gpu_node_vm_size" {
  type = string
}

variable "gpu_enable_autoscaling" {
  type = bool
}

variable "gpu_node_count" {
  type = number
}

variable "gpu_node_min_count" {
  type = number
}

variable "gpu_node_max_count" {
  type = number
}

variable "gpu_node_os_disk_size_gb" {
  type = number
}

variable "gpu_node_labels" {
  type = map(string)
}

variable "gpu_node_taint_enabled" {
  type = bool
}
