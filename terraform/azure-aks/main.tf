# ============================================================
# TEMPLATE: Terraform — Azure Kubernetes Service (AKS)
# WHEN TO USE: Provisioning a production-ready AKS cluster on Azure
# PREREQUISITES: Azure subscription, Azure CLI authenticated
# SECRETS NEEDED: None (uses az login or service principal via env vars)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/azure-aks/, cd/kubernetes/
# MATURITY: Stable
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0" # <-- CHANGE THIS: pin to latest stable
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatesa"
  #   container_name       = "tfstate"
  #   key                  = "aks.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# ---------------------------------------------
# Resource Group
# ---------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# ---------------------------------------------
# Virtual Network + Subnet for AKS
# ---------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_address_space]

  tags = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_prefix]
}

# ---------------------------------------------
# Azure Container Registry (ACR)
# ---------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = replace("acr${var.project}${var.environment}", "-", "") # ACR names must be alphanumeric
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false # Use managed identity instead of admin credentials

  tags = local.common_tags
}

# ---------------------------------------------
# AKS Cluster
# ---------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    os_disk_size_gb     = 128
    max_pods            = 50
    enable_auto_scaling = var.enable_autoscaling
    min_count           = var.enable_autoscaling ? var.node_min_count : null
    max_count           = var.enable_autoscaling ? var.node_max_count : null

    tags = local.common_tags
  }

  # Use system-assigned managed identity (recommended over service principal)
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"    # Azure CNI for VNet integration
    network_policy    = "calico"   # Network policies for pod-level firewall rules
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = local.common_tags
}

# ---------------------------------------------
# Log Analytics Workspace (for Container Insights)
# ---------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
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
