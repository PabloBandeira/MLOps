terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
}

# Kubernetes Provider (configurado con el endpoint de EKS)
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Obtener token de autenticación para Kubernetes
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

# Data source para obtener AZs disponibles
data "aws_availability_zones" "available" {
  state = "available"
}

# Locals para valores reutilizables
locals {
  cluster_name = var.cluster_name
  environment  = var.environment
  
  # Número de AZs para distribuir recursos
  az_count = min(2, length(data.aws_availability_zones.available.names))
  
  # Nombres de subnets
  public_subnet_names  = ["public-az1", "public-az2"]
  private_subnet_names = ["private-az1", "private-az2"]
  
  # Versión de Kubernetes
  k8s_version = var.kubernetes_version
}

