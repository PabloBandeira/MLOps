# ========================================
# WORKSPACE (JUPYTER LAB)
# ========================================
# Deployment y Service para el entorno Jupyter del alumno

# Deployment de Workspace
resource "kubernetes_deployment" "workspace" {
  
  metadata {
    name = "workspace"
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
        container {
          name  = "workspace"
          image = "workspace:latest"
          image_pull_policy = "Never"  # Usar imagen local
          
          port {
            container_port = 8888
            name           = "jupyter"
          }
          
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
          
          # Montar notebooks desde el host (opcional)
          # Nota: En Kind, los volúmenes hostPath son complejos
          # Por ahora, los notebooks están dentro de la imagen
          # Para desarrollo, se pueden copiar al pod con kubectl cp
          
          # Health check
          liveness_probe {
            http_get {
              path = "/"
              port = 8888
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/"
              port = 8888
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
          }
          
          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

# Service de Workspace (NodePort para acceso desde el navegador)
resource "kubernetes_service" "workspace" {
  depends_on = [kubernetes_deployment.workspace]
  
  metadata {
    name = "workspace-service"
    labels = {
      app = "workspace"
    }
  }
  
  spec {
    type = "NodePort"
    
    selector = {
      app = "workspace"
    }
    
    port {
      name        = "jupyter"
      port        = 8888
      target_port = 8888
      node_port   = 30003
    }
  }
}
