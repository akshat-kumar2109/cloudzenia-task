resource "aws_ecr_repository" "app" {
  name = "${var.project}-${var.environment}-app"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project}-${var.environment}-app"
    Environment = var.environment
  }

  force_delete = true
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Null resource for Docker image management
resource "null_resource" "docker_image" {
  triggers = {
    repository_url = aws_ecr_repository.app.repository_url
    app_hash       = filemd5("${path.root}/../app/server.js")
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Build and push the Docker image
      cd ${path.root}/../app
      aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
      docker build -t ${aws_ecr_repository.app.repository_url}:latest .
      docker push ${aws_ecr_repository.app.repository_url}:latest
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Remove all images from the repository before destroying it
      aws ecr batch-delete-image \
        --region us-west-2 \
        --repository-name ${self.triggers.repository_url} \
        --image-ids imageTag=latest || true
    EOT
  }

  depends_on = [aws_ecr_repository.app]
} 