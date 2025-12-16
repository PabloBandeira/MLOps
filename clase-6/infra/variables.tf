# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mlops-cluster-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
  default     = "1.32"
}

# Node Configuration
variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# Storage Configuration
variable "mlflow_volume_size" {
  description = "Size of MLflow EBS volume in GB"
  type        = number
  default     = 50
}

variable "evidently_volume_size" {
  description = "Size of Evidently EBS volume in GB"
  type        = number
  default     = 20
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

# Container Images
variable "mlflow_image" {
  description = "MLflow container image"
  type        = string
  default     = "ghcr.io/mlflow/mlflow:v2.10.0"
}

variable "evidently_image" {
  description = "Evidently container image"
  type        = string
  default     = "evidently/evidently-service:latest"
}

variable "ecr_url" {
  description = "ECR repository URL (format: 123456789012.dkr.ecr.us-east-1.amazonaws.com)"
  type        = string
  default     = ""
}

# Resource Limits
variable "mlflow_cpu_request" {
  description = "MLflow CPU request"
  type        = string
  default     = "250m"
}

variable "mlflow_cpu_limit" {
  description = "MLflow CPU limit"
  type        = string
  default     = "500m"
}

variable "mlflow_memory_request" {
  description = "MLflow memory request"
  type        = string
  default     = "512Mi"
}

variable "mlflow_memory_limit" {
  description = "MLflow memory limit"
  type        = string
  default     = "1Gi"
}

variable "iris_api_cpu_request" {
  description = "Iris API CPU request"
  type        = string
  default     = "100m"
}

variable "iris_api_cpu_limit" {
  description = "Iris API CPU limit"
  type        = string
  default     = "500m"
}

variable "iris_api_memory_request" {
  description = "Iris API memory request"
  type        = string
  default     = "256Mi"
}

variable "iris_api_memory_limit" {
  description = "Iris API memory limit"
  type        = string
  default     = "512Mi"
}

variable "iris_api_replicas" {
  description = "Number of Iris API replicas"
  type        = number
  default     = 2
}

variable "workspace_cpu_request" {
  description = "Workspace CPU request"
  type        = string
  default     = "250m"
}

variable "workspace_cpu_limit" {
  description = "Workspace CPU limit"
  type        = string
  default     = "1000m"
}

variable "workspace_memory_request" {
  description = "Workspace memory request"
  type        = string
  default     = "512Mi"
}

variable "workspace_memory_limit" {
  description = "Workspace memory limit"
  type        = string
  default     = "2Gi"
}

# Tags
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "mlops-clase5"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "mlops-team"
}

