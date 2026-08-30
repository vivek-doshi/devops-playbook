# ---------------------------------------------
# Security Group for EKS Cluster
# ---------------------------------------------
resource "aws_security_group" "eks_cluster" {
  name_prefix = "sg-eks-${var.project}-${var.environment}-"
  vpc_id      = var.vpc_id
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
