# ============================================================================
# OUTPUTS - INFORMACIÓN DE SALIDA
# ============================================================================

# Configuración de kubectl
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

# Información del cluster
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your EKS Kubernetes API"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# Información de VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Información de Security Groups
output "control_plane_sg_id" {
  description = "Security group ID of the control plane"
  value       = aws_security_group.control_plane.id
}

output "nodes_sg_id" {
  description = "Security group ID of the nodes"
  value       = aws_security_group.nodes.id
}

# Información de Roles IAM
output "eks_cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "nodes_role_arn" {
  description = "IAM role ARN for the EKS nodes"
  value       = aws_iam_role.nodes_role.arn
}

# Información de ECR
output "ecr_iris_api_url" {
  description = "ECR URL for Iris API image"
  value       = aws_ecr_repository.iris_api.repository_url
}

output "ecr_workspace_url" {
  description = "ECR URL for Workspace image"
  value       = aws_ecr_repository.workspace.repository_url
}

# Instrucciones para los pasos siguientes
output "next_steps" {
  description = "Next steps to complete the setup"
  value = <<-EOT
    
    ✅ Clúster EKS creado exitosamente!
    
    Próximos pasos:
    
    1. Configura kubectl:
       ${aws_eks_cluster.main.endpoint}
       aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}
    
    2. Verifica que el cluster está ready:
       kubectl get nodes
    
    3. Sube tus imágenes a ECR:
       cd ../app_iris
       docker build -t iris-api:latest .
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
       docker tag iris-api:latest ${aws_ecr_repository.iris_api.repository_url}:latest
       docker push ${aws_ecr_repository.iris_api.repository_url}:latest
       
       cd ../app_workspace
       docker build -t workspace:latest .
       docker tag workspace:latest ${aws_ecr_repository.workspace.repository_url}:latest
       docker push ${aws_ecr_repository.workspace.repository_url}:latest
    
    4. Actualiza terraform.tfvars con:
       ecr_url = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
    
    5. Aplica los deployments:
       terraform apply
    
    6. Obtén las URLs de acceso:
       kubectl get svc -w
    
    ⚠️  Recuerda destruir los recursos cuando termines:
       terraform destroy
  EOT
}

