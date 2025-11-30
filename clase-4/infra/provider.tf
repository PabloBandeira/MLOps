# ========================================
# PROVIDERS
# ========================================
# Define los providers necesarios para gestionar la infraestructura

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Provider de Kubernetes
# Se conecta al clúster Kind que ya fue creado manualmente
# El clúster debe existir antes de ejecutar terraform apply
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-mlops-cluster"
}
