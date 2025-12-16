# ============================================================================
# EVIDENTLY DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "evidently" {
  metadata {
    name      = "evidently"
    namespace = "default"
    labels = {
      app = "evidently"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "evidently"
      }
    }

    template {
      metadata {
        labels = {
          app = "evidently"
        }
      }

      spec {
        container {
          name  = "evidently"
          image = var.evidently_image

          port {
            container_port = 8000
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
            name       = "evidently-data"
            mount_path = "/workspace"
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = 8000
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
              port   = 8000
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "evidently-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.evidently_storage.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_persistent_volume_claim.evidently_storage]
}

# Service para Evidently
resource "kubernetes_service" "evidently" {
  metadata {
    name = "evidently-service"
    labels = {
      app = "evidently"
    }
  }

  spec {
    selector = {
      app = "evidently"
    }

    port {
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
      name        = "http"
    }

    type = "LoadBalancer"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "evidently_service_name" {
  description = "Evidently service name"
  value       = kubernetes_service.evidently.metadata[0].name
}

output "evidently_service_endpoint" {
  description = "Evidently service endpoint"
  value       = try(kubernetes_service.evidently.status[0].load_balancer[0].ingress[0].hostname, "pending...")
}

