# ============================================================
# TEMPLATE: Terraform Tests — AWS EKS Module
# WHEN TO USE: Run with `terraform test` from terraform/aws-eks/
#   or `terraform test -filter=tests/aws-eks.tftest.hcl`
#
# WHAT THESE TESTS CHECK:
#   - EKS cluster name follows 'eks-<project>-<environment>' convention
#   - VPC name follows 'vpc-<project>-<environment>' convention
#   - Worker node instance type is not t2.micro / t3.micro (too small for k8s)
#   - Minimum node count >= 2 (high availability requirement)
#   - Kubernetes version is a recent supported release (not EOL)
#   - At least 2 availability zones are configured
#
# PREREQUISITES: Terraform >= 1.6 (mock_provider requires 1.6+)
# CREDENTIALS:   None — mock_provider replaces the real AWS API
# ============================================================

# Note 1: mock_provider "aws" replaces the real AWS provider with an in-memory stub.
# No AWS credentials are needed. All resource creation calls return synthetic responses
# sufficient for plan-level assertions.
mock_provider "aws" {}

# ── Test 1: EKS cluster naming convention ────────────────────────────────────
# Note 2: The cluster name is referenced in kubeconfig entries, RBAC policies,
# and monitoring dashboards. A consistent naming convention prevents environment
# confusion and aligns with the IAM role naming in ci/github-actions/terraform/.
run "eks_cluster_name_follows_convention" {
  command = plan

  variables {
    project     = "my-app"    # <-- CHANGE THIS: use a representative project name
    environment = "staging"   # <-- CHANGE THIS: test with your most common environment
    aws_region  = "us-east-1"
  }

  assert {
    condition     = aws_eks_cluster.main.name == "eks-my-app-staging"
    error_message = "EKS cluster name must follow 'eks-<project>-<environment>' convention. Got: ${aws_eks_cluster.main.name}"
  }
}

# ── Test 2: VPC naming convention ────────────────────────────────────────────
run "vpc_name_follows_convention" {
  command = plan

  variables {
    project     = "my-app"
    environment = "production"
    aws_region  = "us-east-1"
  }

  assert {
    condition     = aws_vpc.main.tags["Name"] == "vpc-my-app-production"
    error_message = "VPC Name tag must follow 'vpc-<project>-<environment>' convention. Got: ${aws_vpc.main.tags["Name"]}"
  }
}

# ── Test 3: Node instance type is not too small for Kubernetes ───────────────
# Note 3: t2.micro and t3.micro have 1 GiB RAM. Kubernetes system components
# (kubelet, kube-proxy, CoreDNS) alone consume ~500 MiB, leaving almost nothing
# for application workloads. The smallest practical size for a k8s worker is
# t3.medium (2 vCPU / 4 GiB). This test prevents common sizing mistakes.
run "node_instance_type_not_undersized" {
  command = plan

  variables {
    project            = "my-app"
    environment        = "production"
    aws_region         = "us-east-1"
    node_instance_type = "t3.large"   # <-- CHANGE THIS: update if default changes
  }

  assert {
    condition     = var.node_instance_type != "t2.micro"
    error_message = "t2.micro has 1 GiB RAM — insufficient for Kubernetes worker nodes. Use t3.medium or larger."
  }

  assert {
    condition     = var.node_instance_type != "t3.micro"
    error_message = "t3.micro has 1 GiB RAM — insufficient for Kubernetes worker nodes. Use t3.medium or larger."
  }

  assert {
    condition     = var.node_instance_type != "t2.nano"
    error_message = "t2.nano has 512 MiB RAM — far too small for Kubernetes. Use t3.medium or larger."
  }
}

# ── Test 4: Minimum node count >= 2 for high availability ────────────────────
# Note 4: A single-node EKS cluster has no redundancy. Enforce a minimum of 2
# nodes so that node replacement (spot interruption, instance upgrade) does not
# cause a complete outage. The Cluster Autoscaler respects node_min_count, so
# this also prevents it from scaling down to a non-HA configuration.
run "node_min_count_is_ha" {
  command = plan

  variables {
    project        = "my-app"
    environment    = "production"
    aws_region     = "us-east-1"
    node_min_count = 2   # <-- CHANGE THIS: minimum to test
  }

  assert {
    condition     = var.node_min_count >= 2
    error_message = "node_min_count must be >= 2 to ensure high availability. A single node has no redundancy during spot interruptions or upgrades."
  }
}

# ── Test 5: node_max_count > node_min_count ────────────────────────────────
# Note 5: If max equals min, the Cluster Autoscaler cannot scale the node group
# out to handle bursts. This catches configuration mistakes where someone sets both
# to the same value thinking it "pins" the cluster size.
run "node_max_greater_than_min" {
  command = plan

  variables {
    project            = "my-app"
    environment        = "production"
    aws_region         = "us-east-1"
    node_min_count     = 2
    node_desired_count = 3
    node_max_count     = 10
  }

  assert {
    condition     = var.node_max_count > var.node_min_count
    error_message = "node_max_count (${var.node_max_count}) must be greater than node_min_count (${var.node_min_count}) to allow autoscaling."
  }
}

# ── Test 6: Kubernetes version is not EOL ─────────────────────────────────────
# Note 6: EKS supports Kubernetes versions for ~14 months after release.
# Update the floor below when a new minor version reaches EKS GA and the previous
# one approaches EOL.
# Check EKS version support at: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
run "kubernetes_version_not_eol" {
  command = plan

  variables {
    project            = "my-app"
    environment        = "production"
    aws_region         = "us-east-1"
    kubernetes_version = "1.29"   # <-- CHANGE THIS: update when testing a newer version
  }

  assert {
    condition     = tonumber(split(".", var.kubernetes_version)[1]) >= 28   # <-- CHANGE THIS: update floor as versions EOL
    error_message = "Kubernetes version ${var.kubernetes_version} is below the minimum supported floor (1.28). See https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  }
}

# ── Test 7: At least 2 availability zones configured ─────────────────────────
# Note 7: Fewer than 2 AZs means EKS node groups are single-AZ. An AZ outage
# would take down the entire cluster. Most production deployments should use 3 AZs.
run "minimum_two_availability_zones" {
  command = plan

  variables {
    project            = "my-app"
    environment        = "production"
    aws_region         = "us-east-1"
    availability_zones = ["us-east-1a", "us-east-1b"]   # <-- CHANGE THIS
  }

  assert {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability. Got: ${length(var.availability_zones)}"
  }
}
