# ============================================================================
# ECR - ELASTIC CONTAINER REGISTRY
# ============================================================================

# Repositorio para Iris API
resource "aws_ecr_repository" "iris_api" {
  name                 = "iris-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${local.cluster_name}-iris-api-repo"
  }
}

# Repositorio para Workspace
resource "aws_ecr_repository" "workspace" {
  name                 = "workspace"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${local.cluster_name}-workspace-repo"
  }
}

# Lifecycle policies comentadas - agregar después si es necesario
# resource "aws_ecr_lifecycle_policy" "iris_api_policy" {
#   repository = aws_ecr_repository.iris_api.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 10 images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["v"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 10
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }
#
# resource "aws_ecr_lifecycle_policy" "workspace_policy" {
#   repository = aws_ecr_repository.workspace.name
#
#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 10 images"
#         selection = {
#           tagStatus     = "tagged"
#           tagPrefixList = ["v"]
#           countType     = "imageCountMoreThan"
#           countNumber   = 10
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }

# ============================================================================
# OUTPUTS
# ============================================================================

output "iris_api_ecr_repository_url" {
  description = "ECR repository URL for Iris API"
  value       = aws_ecr_repository.iris_api.repository_url
}

output "workspace_ecr_repository_url" {
  description = "ECR repository URL for Workspace"
  value       = aws_ecr_repository.workspace.repository_url
}

output "ecr_registry_url" {
  description = "ECR registry URL"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Data source para obtener Account ID
data "aws_caller_identity" "current" {}

