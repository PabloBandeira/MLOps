# ============================================================================
# IRIS API DEPLOYMENT
# ============================================================================

resource "kubernetes_deployment" "iris_api" {
  metadata {
    name      = "iris-api"
    namespace = "default"
    labels = {
      app = "iris-api"
    }
  }

  spec {
    replicas = var.iris_api_replicas

    selector {
      match_labels = {
        app = "iris-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "iris-api"
        }
      }

      spec {
        # Imagen debe estar en ECR
        container {
          name  = "iris-api"
          image = var.ecr_url != "" ? "${var.ecr_url}/iris-api:latest" : "placeholder-iris-api"

          port {
            container_port = 8000
            name           = "http"
          }

          resources {
            requests = {
              cpu    = var.iris_api_cpu_request
              memory = var.iris_api_memory_request
            }
            limits = {
              cpu    = var.iris_api_cpu_limit
              memory = var.iris_api_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path   = "/health"
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
              path   = "/health"
              port   = 8000
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        # Pod Anti-Affinity: distribuir réplicas en diferentes nodos
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["iris-api"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }
  }
}

# Service para Iris API
resource "kubernetes_service" "iris_api" {
  metadata {
    name = "iris-service"
    labels = {
      app = "iris-api"
    }
  }

  spec {
    selector = {
      app = "iris-api"
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

# Horizontal Pod Autoscaler para Iris API
resource "kubernetes_horizontal_pod_autoscaler_v2" "iris_api" {
  metadata {
    name      = "iris-api-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.iris_api.metadata[0].name
    }

    min_replicas = var.iris_api_replicas
    max_replicas = 10

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        policy {
          type                 = "Percent"
          value                = 50
          period_seconds       = 60
        }
      }
      scale_up {
        stabilization_window_seconds = 0
        policy {
          type                 = "Percent"
          value                = 100
          period_seconds       = 30
        }
      }
    }
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "iris_api_service_name" {
  description = "Iris API service name"
  value       = kubernetes_service.iris_api.metadata[0].name
}

output "iris_api_service_endpoint" {
  description = "Iris API service endpoint"
  value       = try(kubernetes_service.iris_api.status[0].load_balancer[0].ingress[0].hostname, "pending...")
}

output "iris_api_replicas" {
  description = "Number of Iris API replicas"
  value       = var.iris_api_replicas
}

