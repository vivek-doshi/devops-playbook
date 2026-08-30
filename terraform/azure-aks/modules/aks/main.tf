# ---------------------------------------------
# AKS Cluster
# ---------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project}-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.location
  dns_prefix          = "${var.project}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "system"
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    vnet_subnet_id       = var.aks_subnet_id
    os_disk_size_gb      = 128
    max_pods             = 50
    auto_scaling_enabled = var.enable_autoscaling
    min_count            = var.enable_autoscaling ? var.node_min_count : null
    max_count            = var.enable_autoscaling ? var.node_max_count : null

    tags = var.common_tags
  }

  # Use system-assigned managed identity (recommended over service principal)
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"  # Azure CNI for VNet integration
    network_policy    = "calico" # Network policies for pod-level firewall rules
    load_balancer_sku = "standard"
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.common_tags
}

# ---------------------------------------------
# GPU Node Pool (optional)
# ---------------------------------------------
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count                 = var.gpu_node_pool_enabled ? 1 : 0
  name                  = var.gpu_node_pool_name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.gpu_node_vm_size
  mode                  = "User"
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = var.gpu_node_os_disk_size_gb
  max_pods              = 50
  auto_scaling_enabled  = var.gpu_enable_autoscaling
  node_count            = var.gpu_enable_autoscaling ? null : var.gpu_node_count
  min_count             = var.gpu_enable_autoscaling ? var.gpu_node_min_count : null
  max_count             = var.gpu_enable_autoscaling ? var.gpu_node_max_count : null
  node_labels           = var.gpu_node_labels
  node_taints           = var.gpu_node_taint_enabled ? ["nvidia.com/gpu=dedicated:NoSchedule"] : []

  tags = merge(var.common_tags, {
    NodePool = "gpu"
  })
}
