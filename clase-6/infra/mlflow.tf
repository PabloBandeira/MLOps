# ============================================================================
# MLFLOW DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "mlflow" {
  metadata {
    name      = "mlflow"
    namespace = "default"
    labels = {
      app = "mlflow"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mlflow"
      }
    }

    template {
      metadata {
        labels = {
          app = "mlflow"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.mlflow.metadata[0].name

        container {
          name  = "mlflow"
          image = var.mlflow_image

          port {
            container_port = 5000
            name           = "http"
          }

          resources {
            requests = {
              cpu    = var.mlflow_cpu_request
              memory = var.mlflow_memory_request
            }
            limits = {
              cpu    = var.mlflow_cpu_limit
              memory = var.mlflow_memory_limit
            }
          }

          volume_mount {
            name       = "mlflow-data"
            mount_path = "/mlflow/data"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = 5000
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = 5000
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "mlflow-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mlflow_storage.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.mlflow_storage]
}

# Service para MLflow
resource "kubernetes_service" "mlflow" {
  metadata {
    name = "mlflow-service"
    labels = {
      app = "mlflow"
    }
  }

  spec {
    selector = {
      app = "mlflow"
    }

    port {
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
      name        = "http"
    }

    type = "LoadBalancer"
  }
}

# Service Account para MLflow
resource "kubernetes_service_account" "mlflow" {
  metadata {
    name      = "mlflow-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.mlflow_sa_role.arn
    }
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "mlflow_service_name" {
  description = "MLflow service name"
  value       = kubernetes_service.mlflow.metadata[0].name
}

output "mlflow_service_endpoint" {
  description = "MLflow service endpoint"
  value       = try(kubernetes_service.mlflow.status[0].load_balancer[0].ingress[0].hostname, "pending...")
}

