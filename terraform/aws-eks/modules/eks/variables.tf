variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "node_desired_count" {
  type = number
}

variable "node_min_count" {
  type = number
}

variable "node_max_count" {
  type = number
}

variable "common_tags" {
  type = map(string)
}

variable "cluster_policy_attachment_ids" {
  description = "Forces this module to wait until the cluster IAM policies are attached"
  type        = list(string)
}

variable "node_policy_attachment_ids" {
  description = "Forces this module to wait until the node IAM policies are attached"
  type        = list(string)
}

variable "gpu_node_group_enabled" {
  type = bool
}

variable "gpu_node_pool_name" {
  type    = string
  default = "ng-gpu"
}

variable "gpu_instance_types" {
  type = list(string)
}

variable "gpu_capacity_type" {
  type = string
}

variable "gpu_ami_type" {
  type = string
}

variable "gpu_disk_size" {
  type = number
}

variable "gpu_labels" {
  type = map(string)
}

variable "gpu_node_taint_enabled" {
  type = bool
}

variable "gpu_desired_count" {
  type = number
}

variable "gpu_min_count" {
  type = number
}

variable "gpu_max_count" {
  type = number
}
