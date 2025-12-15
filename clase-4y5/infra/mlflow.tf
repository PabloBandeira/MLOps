# ========================================
# MLFLOW SERVER
# ========================================
# Deployment y Service para MLflow Tracking Server

# Deployment de MLflow
resource "kubernetes_deployment" "mlflow" {
  
  metadata {
    name = "mlflow"
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
        container {
          name  = "mlflow"
          image = "ghcr.io/mlflow/mlflow:v2.10.0"
          
          command = ["mlflow"]
          args = [
            "server",
            "--host", "0.0.0.0",
            "--port", "5000",
            "--backend-store-uri", "sqlite:////tmp/mlflow.db",
            "--default-artifact-root", "/tmp/artifacts"
          ]
          
          port {
            container_port = 5000
            name           = "http"
          }
          
          # Health check
          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
          
          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

# Service de MLflow (NodePort para acceso externo)
resource "kubernetes_service" "mlflow" {
  depends_on = [kubernetes_deployment.mlflow]
  
  metadata {
    name = "mlflow-service"
    labels = {
      app = "mlflow"
    }
  }
  
  spec {
    type = "NodePort"
    
    selector = {
      app = "mlflow"
    }
    
    port {
      name        = "http"
      port        = 5000
      target_port = 5000
      node_port   = 30001
    }
  }
}
