# ============================================================================
# WORKSPACE (JUPYTER LAB) DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "workspace"
    namespace = "default"
    labels = {
      app = "workspace"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "workspace"
      }
    }

    template {
      metadata {
        labels = {
          app = "workspace"
        }
      }

      spec {
        # Imagen debe estar en ECR
        container {
          name  = "workspace"
          image = var.ecr_url != "" ? "${var.ecr_url}/workspace:latest" : "placeholder-workspace"

          port {
            container_port = 8888
            name           = "http"
          }

          resources {
            requests = {
              cpu    = var.workspace_cpu_request
              memory = var.workspace_memory_request
            }
            limits = {
              cpu    = var.workspace_cpu_limit
              memory = var.workspace_memory_limit
            }
          }

          # Environment variables para conectar a otros servicios
          env {
            name  = "MLFLOW_TRACKING_URI"
            value = "http://mlflow-service:5000"
          }

          env {
            name  = "EVIDENTLY_SERVICE_URL"
            value = "http://evidently-service:8000"
          }

          env {
            name  = "IRIS_API_URI"
            value = "http://iris-service:8000"
          }

          env {
            name  = "IRIS_API_URL"
            value = "http://iris-service:8000"
          }

          env {
            name  = "JUPYTER_ENABLE_LAB"
            value = "yes"
          }

          liveness_probe {
            http_get {
              path   = "/lab"
              port   = 8888
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/lab"
              port   = 8888
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }
}

# Service para Workspace
resource "kubernetes_service" "workspace" {
  metadata {
    name = "workspace-service"
    labels = {
      app = "workspace"
    }
  }

  spec {
    selector = {
      app = "workspace"
    }

    port {
      port        = 8888
      target_port = 8888
      protocol    = "TCP"
      name        = "http"
    }

    type = "LoadBalancer"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "workspace_service_name" {
  description = "Workspace service name"
  value       = kubernetes_service.workspace.metadata[0].name
}

output "workspace_service_endpoint" {
  description = "Workspace service endpoint"
  value       = try(kubernetes_service.workspace.status[0].load_balancer[0].ingress[0].hostname, "pending...")
}

