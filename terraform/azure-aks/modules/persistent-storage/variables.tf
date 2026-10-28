variable "enable_persistent_storage" {
  description = "Whether to provision the selected persistent-storage prerequisite."
  type        = bool
}

variable "storage_type" {
  description = "managed_disk uses the AKS CSI driver; azure_file creates an Azure Files account and share."
  type        = string
  default     = "managed_disk"

  validation {
    condition     = contains(["managed_disk", "azure_file"], var.storage_type)
    error_message = "storage_type must be managed_disk or azure_file."
  }
}

variable "project" { type = string }
variable "environment" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "common_tags" { type = map(string) }

variable "file_share_name" {
  description = "Azure Files share name when storage_type is azure_file."
  type        = string
  default     = "shared-data"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])?$", var.file_share_name))
    error_message = "file_share_name must be 3-63 lowercase alphanumeric or hyphen characters."
  }
}

variable "file_share_quota_gb" {
  type        = number
  default     = 100
  description = "Azure Files share quota in GiB."

  validation {
    condition     = var.file_share_quota_gb >= 1 && var.file_share_quota_gb <= 102400
    error_message = "file_share_quota_gb must be between 1 and 102400."
  }
}

variable "storage_account_replication_type" {
  type        = string
  default     = "LRS"
  description = "Replication for the Azure Files storage account."

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be a supported Azure Storage replication type."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enable only when the storage account has an approved public-network exception."
}
