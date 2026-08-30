variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name — used to tag subnets for the Kubernetes cloud-controller"
  type        = string
}
