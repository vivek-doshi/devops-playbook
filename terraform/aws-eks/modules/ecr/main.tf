# ---------------------------------------------
# ECR Repository
# ---------------------------------------------
resource "aws_ecr_repository" "main" {
  name                 = "${var.project}-${var.environment}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true # Automatically scan images for CVEs
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
