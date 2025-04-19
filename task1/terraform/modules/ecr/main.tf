locals {
  name = "${var.project}-${var.environment}"
}

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repository_names)

  name = "${local.name}-${each.key}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${local.name}-${each.key}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = aws_ecr_repository.main

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Null resource to delete ECR images during destroy
resource "null_resource" "delete_ecr_images" {
  for_each = aws_ecr_repository.main

  triggers = {
    repository_name = each.value.name
  }

  # This will run during destroy
  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
#!/bin/bash
set -e

REPO_NAME="${self.triggers.repository_name}"
echo "Processing repository: $REPO_NAME"

# Get list of image digests
IMAGES=$(aws ecr list-images --repository-name "$REPO_NAME" --query 'imageIds[*].imageDigest' --output text)

if [ ! -z "$IMAGES" ]; then
    echo "Found images in repository: $REPO_NAME"
    
    # Convert space-separated digests into JSON array of image objects
    IMAGE_IDS="["
    for digest in $IMAGES; do
        if [ "$IMAGE_IDS" != "[" ]; then
            IMAGE_IDS="$IMAGE_IDS,"
        fi
        IMAGE_IDS="$IMAGE_IDS{\"imageDigest\":\"$digest\"}"
    done
    IMAGE_IDS="$IMAGE_IDS]"
    
    echo "Deleting images from repository: $REPO_NAME"
    aws ecr batch-delete-image \
        --repository-name "$REPO_NAME" \
        --image-ids "$IMAGE_IDS" || echo "Failed to delete images from $REPO_NAME"
else
    echo "No images found in repository: $REPO_NAME"
fi
EOF
  }

  depends_on = [aws_ecr_repository.main]
} 