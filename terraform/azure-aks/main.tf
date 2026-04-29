# ============================================================
# TEMPLATE: Terraform — Azure Kubernetes Service (AKS)
# WHEN TO USE: Provisioning a production-ready AKS cluster on Azure
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-aks/, cd/kubernetes/
# MATURITY: Stable
# ============================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    azurerm = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/azurerm"
      version = "~> 4.70.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "aks.terraform.tfstate"
  # }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "azurerm" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  features {}
}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
# Note 7: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  # Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location = var.location

  tags = local.common_tags
# Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Virtual Network + Subnet for AKS
# ---------------------------------------------
resource "azurerm_virtual_network" "main" {
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]

  # Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = local.common_tags
}

# Note 13: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  address_prefixes     = [var.aks_subnet_prefix]
}

# ---------------------------------------------
# Azure Container Registry (ACR)
# ---------------------------------------------
# Note 16: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_container_registry" "main" {
  name                = replace("acr${var.project}${var.environment}", "-", "") # ACR names must be alphanumeric
  # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identity instead of admin credentials

  # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = local.common_tags
}

# ---------------------------------------------
# AKS Cluster
# ---------------------------------------------
# Note 20: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default_node_pool {
    name                = "system"
    # Note 24: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    vnet_subnet_id      = azurerm_subnet.aks.id
    os_disk_size_gb     = 128
    # Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    max_pods            = 50
    enable_auto_scaling = var.enable_autoscaling
    # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    min_count           = var.enable_autoscaling ? var.node_min_count : null
    max_count           = var.enable_autoscaling ? var.node_max_count : null

    # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    tags = local.common_tags
  }

  # Use system-assigned managed identity (recommended over service principal)
  # Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  identity {
    type = "SystemAssigned"
  # Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  network_profile {
    # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    network_plugin    = "azure"    # Azure CNI for VNet integration
    network_policy    = "calico"   # Network policies for pod-level firewall rules
    # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    # Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    dns_service_ip    = "10.0.0.10"
  }

  # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  tags = local.common_tags
# Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Log Analytics Workspace (for Container Insights)
# ---------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name                = "law-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# ---------------------------------------------
# Grant AKS pull access to ACR
# ---------------------------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# ---------------------------------------------
# Common Tags
# ---------------------------------------------
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
