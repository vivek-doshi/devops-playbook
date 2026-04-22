# ============================================================
# TEMPLATE: Terraform — AWS ECS Fargate
# WHEN TO USE: Running containers on AWS without managing servers
# PREREQUISITES: AWS account, AWS CLI authenticated
# SECRETS NEEDED: None (uses aws configure or IAM role)
# WHAT TO CHANGE: Lines marked with # <-- CHANGE THIS
# RELATED FILES: cd/targets/aws-ecs/
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
  #   key            = "ecs/terraform.tfstate"
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
    Name = "snet-public-${var.availability_zones[count.index]}"
  }
# Note 17: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_subnet" "private" {
  # Note 18: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  # Note 19: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  # Note 20: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = {
    Name = "snet-private-${var.availability_zones[count.index]}"
  # Note 21: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Note 22: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  # Note 23: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = { Name = "igw-${var.project}-${var.environment}" }
}

# Note 24: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_eip" "nat" {
  domain = "vpc"
  # Note 25: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags   = { Name = "eip-nat-${var.project}-${var.environment}" }
}

# Note 26: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  # Note 27: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnet_id     = aws_subnet.public[0].id

  tags       = { Name = "nat-${var.project}-${var.environment}" }
  # Note 28: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  depends_on = [aws_internet_gateway.main]
}

# Note 29: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  # Note 30: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route {
    cidr_block = "0.0.0.0/0"
    # Note 31: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    gateway_id = aws_internet_gateway.main.id
  }
  # Note 32: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = { Name = "rt-public-${var.project}-${var.environment}" }
}

# Note 33: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  # Note 34: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route {
    cidr_block     = "0.0.0.0/0"
    # Note 35: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    nat_gateway_id = aws_nat_gateway.main.id
  }
  # Note 36: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  tags = { Name = "rt-private-${var.project}-${var.environment}" }
}

# Note 37: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  # Note 38: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
# Note 39: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_route_table_association" "private" {
  # Note 40: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  # Note 41: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------
# ECR Repository
# ---------------------------------------------
# Note 42: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_ecr_repository" "main" {
  name                 = "${var.project}-${var.environment}"
  # Note 43: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    # Note 44: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    scan_on_push = true
  }

  # Note 45: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  encryption_configuration {
    encryption_type = "AES256"
  # Note 46: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# ---------------------------------------------
# ECS Cluster
# ---------------------------------------------
# Note 47: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_ecs_cluster" "main" {
  name = "ecs-${var.project}-${var.environment}"

  # Note 48: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  setting {
    name  = "containerInsights"
    # Note 49: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    value = "enabled"
  }
# Note 50: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# ECS Task Execution Role
# ---------------------------------------------
resource "aws_iam_role" "ecs_task_execution" {
  # Note 51: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name = "role-ecs-exec-${var.project}-${var.environment}"

  assume_role_policy = jsonencode({
    # Note 52: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Version = "2012-10-17"
    Statement = [{
      # Note 53: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Action = "sts:AssumeRole"
      Effect = "Allow"
      # Note 54: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      # Note 55: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      }
    }]
  # Note 56: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  })
}

# Note 57: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  # Note 58: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role (for the application itself)
# Note 59: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_iam_role" "ecs_task" {
  name = "role-ecs-task-${var.project}-${var.environment}"

  # Note 60: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    # Note 61: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    Statement = [{
      Action = "sts:AssumeRole"
      # Note 62: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      Effect = "Allow"
      Principal = {
        # Note 63: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        Service = "ecs-tasks.amazonaws.com"
      }
    # Note 64: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }]
  })
# Note 65: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# CloudWatch Log Group
# ---------------------------------------------
resource "aws_cloudwatch_log_group" "main" {
  # Note 66: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 30
# Note 67: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# ECS Task Definition
# ---------------------------------------------
resource "aws_ecs_task_definition" "main" {
  # Note 68: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  family                   = "${var.project}-${var.environment}"
  network_mode             = "awsvpc"
  # Note 69: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  # Note 70: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  # Note 71: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    # Note 72: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    name  = var.project
    image = "${aws_ecr_repository.main.repository_url}:latest" # <-- CHANGE THIS: use a specific tag, not latest
    # Note 73: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    portMappings = [{
      containerPort = var.container_port
      # Note 74: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      hostPort      = var.container_port
      protocol      = "tcp"
    # Note 75: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }]
    logConfiguration = {
      # Note 76: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      logDriver = "awslogs"
      options = {
        # Note 77: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        awslogs-group         = aws_cloudwatch_log_group.main.name
        awslogs-region        = var.aws_region
        # Note 78: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
        awslogs-stream-prefix = "ecs"
      }
    # Note 79: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    }
    healthCheck = {
      # Note 80: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
      interval    = 30
      # Note 81: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      timeout     = 5
      retries     = 3
      # Note 82: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
      startPeriod = 60
    }
    # Note 83: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    essential = true
  }])
# Note 84: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# Application Load Balancer
# ---------------------------------------------
resource "aws_lb" "main" {
  # Note 85: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name               = "alb-${var.project}-${var.environment}"
  internal           = false
  # Note 86: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  # Note 87: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  subnets            = aws_subnet.public[*].id

  tags = { Name = "alb-${var.project}-${var.environment}" }
# Note 88: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

resource "aws_lb_target_group" "main" {
  # Note 89: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name        = "tg-${var.project}-${var.environment}"
  port        = var.container_port
  # Note 90: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  # Note 91: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  target_type = "ip"

  health_check {
    # Note 92: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    path                = "/health" # <-- CHANGE THIS: your health endpoint
    healthy_threshold   = 2
    # Note 93: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    unhealthy_threshold = 3
    timeout             = 5
    # Note 94: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    interval            = 30
    matcher             = "200"
  # Note 95: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  }
}

# Note 96: Terraform blocks declare desired state, allowing repeatable provisioning and easier drift detection.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  # Note 97: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  port              = 80
  protocol          = "HTTP"

  # Note 98: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  default_action {
    type             = "forward"
    # Note 99: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
    target_group_arn = aws_lb_target_group.main.arn
  }

  # For production, add HTTPS listener instead:
  # port     = 443
  # protocol = "HTTPS"
  # certificate_arn = var.acm_certificate_arn
# Note 100: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
}

# ---------------------------------------------
# ECS Service
# ---------------------------------------------
resource "aws_ecs_service" "main" {
  # Note 101: This line contributes to the system's declarative intent, helping future readers reason about behavior and change impact.
  name            = "${var.project}-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.project
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}

# ---------------------------------------------
# Security Groups
# ---------------------------------------------
resource "aws_security_group" "alb" {
  name_prefix = "sg-alb-${var.project}-${var.environment}-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-alb-${var.project}-${var.environment}" }
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "sg-ecs-${var.project}-${var.environment}-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ECS tasks"

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-ecs-${var.project}-${var.environment}" }
}

# ---------------------------------------------
# Auto Scaling
# ---------------------------------------------
resource "aws_appautoscaling_target" "main" {
  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

# ---------------------------------------------
# Locals
# ---------------------------------------------
locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
