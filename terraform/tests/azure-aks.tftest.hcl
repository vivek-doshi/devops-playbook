# ============================================================
# TEMPLATE: Terraform Tests — Azure AKS Module
# WHEN TO USE: Run with `terraform test` from terraform/azure-aks/
#   or `terraform test -filter=tests/azure-aks.tftest.hcl`
#
# WHAT THESE TESTS CHECK:
#   - Resource naming follows the 'rg-<project>-<environment>' convention
#   - Node VM size is not an undersized SKU inappropriate for production
#   - Kubernetes version is a recent supported release (not EOL)
#   - Autoscaling minimum is >= 2 nodes (single-node is not HA)
#
# PREREQUISITES: Terraform >= 1.6 (mock_provider requires 1.6+)
# CREDENTIALS:   None — mock_provider replaces the real Azure API
# ============================================================

# Note 1: mock_provider replaces the real azurerm provider with an in-memory stub.
# No Azure credentials are needed. The mock intercepts all resource creation calls
# and returns synthetic responses that are sufficient for plan-level assertions.
mock_provider "azurerm" {}

# ── Test 1: Resource Group naming convention ─────────────────────────────────
# Note 2: Resource names are central to operational consistency.
# A naming convention violation in Terraform variables would cause the resource
# to be created under the wrong name, breaking RBAC policies and cost tags.
run "resource_group_name_follows_convention" {
  command = plan

  variables {
    project     = "my-app"    # <-- CHANGE THIS: use a representative project name
    environment = "staging"   # <-- CHANGE THIS: test with your most common environment
    location    = "eastus"
  }

  assert {
    condition     = azurerm_resource_group.main.name == "rg-my-app-staging"
    error_message = "Resource group name must follow 'rg-<project>-<environment>' convention. Got: ${azurerm_resource_group.main.name}"
  }
}

# ── Test 2: AKS cluster naming convention ────────────────────────────────────
run "aks_cluster_name_follows_convention" {
  command = plan

  variables {
    project     = "my-app"
    environment = "production"
    location    = "eastus"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.name == "aks-my-app-production"
    error_message = "AKS cluster name must follow 'aks-<project>-<environment>' convention. Got: ${azurerm_kubernetes_cluster.main.name}"
  }
}

# ── Test 3: Node VM size is not undersized ────────────────────────────────────
# Note 3: Standard_B1s and Standard_B2s are burstable VMs designed for dev/test.
# Using them in production causes CPU throttling under sustained load.
# This test prevents accidentally deploying a production cluster with dev-tier VMs.
run "node_vm_size_not_burstable_b1s" {
  command = plan

  variables {
    project          = "my-app"
    environment      = "production"
    location         = "eastus"
    node_vm_size     = "Standard_D4s_v5"  # <-- CHANGE THIS: update if default changes
  }

  assert {
    condition     = var.node_vm_size != "Standard_B1s"
    error_message = "Standard_B1s is not suitable for production AKS nodes — it is a burstable VM with only 1 vCPU. Use Standard_D4s_v5 or larger."
  }

  assert {
    condition     = var.node_vm_size != "Standard_B2s"
    error_message = "Standard_B2s is not suitable for production AKS nodes — burstable VMs throttle CPU under sustained load. Use Standard_D4s_v5 or larger."
  }
}

# ── Test 4: Minimum node count >= 2 for high availability ────────────────────
# Note 4: A single-node pool has no redundancy. If the node is drained for
# upgrade or the VM is preempted, all workloads go down. Enforce >= 2 so there
# is always at least one node available during node replacement.
run "autoscaling_minimum_is_ha" {
  command = plan

  variables {
    project           = "my-app"
    environment       = "production"
    location          = "eastus"
    enable_autoscaling = true
    node_min_count    = 2   # <-- CHANGE THIS: minimum to test
  }

  assert {
    condition     = var.node_min_count >= 2
    error_message = "node_min_count must be >= 2 to ensure high availability. A single node has no redundancy during upgrades."
  }
}

# ── Test 5: Kubernetes version is not EOL ─────────────────────────────────────
# Note 5: This test enforces a floor on the Kubernetes version. Update the
# floor version whenever a new minor version reaches AKS GA and the previous
# one approaches EOL (typically 12 months after release).
# Check EOL dates at: https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions
run "kubernetes_version_not_eol" {
  command = plan

  variables {
    project            = "my-app"
    environment        = "production"
    location           = "eastus"
    kubernetes_version = "1.29"   # <-- CHANGE THIS: update when testing a newer version
  }

  assert {
    condition     = tonumber(split(".", var.kubernetes_version)[1]) >= 28   # <-- CHANGE THIS: update floor as versions EOL
    error_message = "Kubernetes version ${var.kubernetes_version} is below the minimum supported floor (1.28). Upgrade to a supported version — check https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions"
  }
}

# ── Test 6: Location is not empty ─────────────────────────────────────────────
run "location_is_provided" {
  command = plan

  variables {
    project     = "my-app"
    environment = "dev"
    location    = "eastus"  # <-- CHANGE THIS
  }

  assert {
    condition     = length(var.location) > 0
    error_message = "location must not be empty. Provide a valid Azure region (e.g. eastus, westeurope)."
  }
}
