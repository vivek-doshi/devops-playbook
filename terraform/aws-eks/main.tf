# ============================================================
# TEMPLATE: Terraform — Amazon Elastic Kubernetes Service (EKS)
# WHEN TO USE: Provisioning a production-ready EKS cluster on AWS
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-eks/, cd/kubernetes/
# MATURITY: Stable
# ============================================================

# Note 1: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
terraform {
  required_version = ">= 1.5.0"

  # Note 2: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  required_providers {
    aws = {
      # Note 3: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      source  = "hashicorp/aws"
      version = "~> 5.31.0" # <-- CHANGE THIS: pin to latest stable
    # Note 4: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
# Note 5: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

provider "aws" {
  # Note 6: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  region = var.aws_region

  default_tags {
    # Note 7: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    tags = local.common_tags
  }
# Note 8: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# VPC + Subnets
# ---------------------------------------------
resource "aws_vpc" "main" {
  # Note 9: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  # Note 10: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  enable_dns_support   = true

  tags = {
    # Note 11: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Name = "vpc-${var.project}-${var.environment}"
  }
# Note 12: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# Public subnets (for load balancers)
resource "aws_subnet" "public" {
  # Note 13: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  # Note 14: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  # Note 15: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  map_public_ip_on_launch = true

  tags = {
    # Note 16: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Name                                        = "snet-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    # Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
# Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# Private subnets (for EKS nodes)
resource "aws_subnet" "private" {
  # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name                                        = "snet-private-${var.availability_zones[count.index]}"
    # Note 22: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Internet Gateway
# Note 24: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name = "igw-${var.project}-${var.environment}"
  # Note 26: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Elastic IP for NAT Gateway
# Note 27: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_eip" "nat" {
  domain = "vpc"

  # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name = "eip-nat-${var.project}-${var.environment}"
  # Note 29: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# NAT Gateway (allows private subnets to reach the internet)
# Note 30: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnet_id     = aws_subnet.public[0].id

  tags = {
    # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Name = "nat-${var.project}-${var.environment}"
  }

  # Note 33: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  depends_on = [aws_internet_gateway.main]
}

# Route tables
# Note 34: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route {
    cidr_block = "0.0.0.0/0"
    # Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    gateway_id = aws_internet_gateway.main.id
  }

  # Note 37: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name = "rt-public-${var.project}-${var.environment}"
  # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Note 39: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route {
    cidr_block     = "0.0.0.0/0"
    # Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # Note 42: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name = "rt-private-${var.project}-${var.environment}"
  # Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Note 44: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  # Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
# Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_route_table_association" "private" {
  # Note 47: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  # Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------
# ECR Repository
# ---------------------------------------------
# Note 49: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_ecr_repository" "main" {
  name                 = "${var.project}-${var.environment}"
  # Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  # Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  image_scanning_configuration {
    scan_on_push = true # Automatically scan images for CVEs
  # Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }

  encryption_configuration {
    # Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    encryption_type = "AES256"
  }
# Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# EKS Cluster IAM Role
# ---------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  # Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name = "role-eks-cluster-${var.project}-${var.environment}"

  assume_role_policy = jsonencode({
    # Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Version = "2012-10-17"
    Statement = [{
      # Note 57: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Action = "sts:AssumeRole"
      Effect = "Allow"
      # Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Principal = {
        Service = "eks.amazonaws.com"
      # Note 59: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      }
    }]
  # Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  })
}

# Note 61: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  # Note 62: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Note 63: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  # Note 64: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ---------------------------------------------
# EKS Node Group IAM Role
# ---------------------------------------------
# Note 65: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role" "eks_nodes" {
  name = "role-eks-nodes-${var.project}-${var.environment}"

  # Note 66: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    # Note 67: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Statement = [{
      Action = "sts:AssumeRole"
      # Note 68: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Effect = "Allow"
      Principal = {
        # Note 69: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        Service = "ec2.amazonaws.com"
      }
    # Note 70: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }]
  })
# Note 71: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  # Note 72: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# Note 73: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  # Note 74: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# Note 75: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  # Note 76: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# Note 77: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# EKS Cluster
# ---------------------------------------------
resource "aws_eks_cluster" "main" {
  # Note 78: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name     = local.cluster_name
  version  = var.kubernetes_version
  # Note 79: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # Note 80: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true # <-- CHANGE THIS: set to false for private clusters
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# ---------------------------------------------
# EKS Managed Node Group
# ---------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ng-${var.project}-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_count
    min_size     = var.node_min_count
    max_size     = var.node_max_count
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}

resource "aws_eks_node_group" "gpu" {
  count           = var.gpu_node_group_enabled ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ng-gpu-${var.project}-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.gpu_instance_types
  capacity_type   = var.gpu_capacity_type
  ami_type        = var.gpu_ami_type
  disk_size       = var.gpu_disk_size
  labels          = var.gpu_labels

  scaling_config {
    desired_size = var.gpu_desired_count
    min_size     = var.gpu_min_count
    max_size     = var.gpu_max_count
  }

  dynamic "taint" {
    for_each = var.gpu_node_taint_enabled ? [1] : []
    content {
      key    = "nvidia.com/gpu"
      value  = "dedicated"
      effect = "NO_SCHEDULE"
    }
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name     = "ng-gpu-${var.project}-${var.environment}"
    NodePool = "gpu"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}

# ---------------------------------------------
# Security Group for EKS Cluster
# ---------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name_prefix = "sg-eks-${var.project}-${var.environment}-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for EKS cluster control plane"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "sg-eks-${var.project}-${var.environment}"
  }
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  cluster_name = "eks-${var.project}-${var.environment}"
  common_tags = {
    CostCenter  = var.cost_center
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
