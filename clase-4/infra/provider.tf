# ========================================
# PROVIDERS
# ========================================
# Define los providers necesarios para gestionar la infraestructura

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Provider de Kind
# Gestiona el clúster local de Kubernetes
provider "kind" {}

# Provider de Kubernetes
# Gestiona los recursos dentro del clúster
provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "kind-mlops-cluster"
}

