# ========================================
# VARIABLES
# ========================================
# Definición de variables para la infraestructura

variable "cluster_name" {
  description = "Nombre del clúster Kind"
  type        = string
  default     = "mlops-cluster"
}

variable "mlflow_node_port" {
  description = "Puerto NodePort para MLflow UI"
  type        = number
  default     = 30001
}

variable "evidently_node_port" {
  description = "Puerto NodePort para Evidently UI"
  type        = number
  default     = 30002
}

variable "workspace_node_port" {
  description = "Puerto NodePort para Jupyter Lab"
  type        = number
  default     = 30003
}

variable "iris_api_node_port" {
  description = "Puerto NodePort para Iris API"
  type        = number
  default     = 30004
}

variable "iris_api_replicas" {
  description = "Número de réplicas del Iris API"
  type        = number
  default     = 2
}
