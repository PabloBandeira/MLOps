# ============================================================================
# TERRAFORM VARIABLES - EDITA ESTOS VALORES SEGÚN TUS NECESIDADES
# ============================================================================
# ⚠️ IMPORTANTE: NO commitees este archivo si contiene secretos
# ============================================================================

# AWS Region
aws_region = "us-east-1"

# EKS Cluster Configuration
cluster_name        = "mlops-cluster-dev"
kubernetes_version  = "1.32"

# Node Configuration (¡IMPORTANTE PARA COSTOS!)
# Para development: usar t3.micro o t3.small
# Para testing: usar t3.medium
# Para production: usar t3.large o mayor
node_instance_type = "t3.micro"
desired_capacity   = 1
min_capacity       = 1
max_capacity       = 4

# Network Configuration
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]

# Storage Configuration
mlflow_volume_size    = 50
evidently_volume_size = 20
ebs_volume_type       = "gp3"

# Container Images
# Nota: MLflow y Evidently usan imágenes públicas
# Iris API y Workspace deben estar en ECR (completa la URL)
mlflow_image     = "ghcr.io/mlflow/mlflow:v2.10.0"
evidently_image  = "evidently/evidently-service:latest"

# COMPLETA ESTO después de crear ECR:
# ecr_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
ecr_url = ""

# Resource Requests and Limits (recomendado: no cambiar)
mlflow_cpu_request         = "250m"
mlflow_cpu_limit           = "500m"
mlflow_memory_request      = "512Mi"
mlflow_memory_limit        = "1Gi"
iris_api_cpu_request       = "100m"
iris_api_cpu_limit         = "500m"
iris_api_memory_request    = "256Mi"
iris_api_memory_limit      = "512Mi"
iris_api_replicas          = 2
workspace_cpu_request      = "250m"
workspace_cpu_limit        = "1000m"
workspace_memory_request   = "512Mi"
workspace_memory_limit     = "2Gi"

# Tags for Organization
environment = "development"
project     = "mlops-clase5"
owner       = "PabloB"

# ============================================================================
# INSTRUCCIONES:
# 1. Reemplaza "tu-nombre" con tu nombre
# 2. Asegúrate de que aws_region sea correcto
# 3. Después de crear ECR, actualiza ecr_url
# 4. Para ahorrar costos, usa: node_instance_type = "t3.small"
# 5. Para desarrollo rápido: desired_capacity = 1
# ============================================================================

