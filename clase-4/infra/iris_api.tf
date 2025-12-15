# ========================================
# IRIS API
# ========================================
# Deployment y Service para la API de predicción Iris
# Usa el patrón inmutable: modelo entrenado durante el build

# Deployment de Iris API (2 réplicas para alta disponibilidad)
resource "kubernetes_deployment" "iris_api" {
  
  metadata {
    name = "iris-api"
    labels = {
      app = "iris-api"
    }
  }
  
  spec {
    replicas = 4  # Alta disponibilidad
    
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
        container {
          name  = "iris-api"
          image = "iris-api:latest"
          image_pull_policy = "Never"  # Usar imagen local cargada con kind load
          
          port {
            container_port = 8000
            name           = "http"
          }
          
          # Health checks
          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
          
          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

# Service de Iris API
# ClusterIP: Solo accesible dentro del clúster (desde Jupyter)
# También exponemos con NodePort para acceso directo si se necesita
resource "kubernetes_service" "iris_api" {
  depends_on = [kubernetes_deployment.iris_api]
  
  metadata {
    name = "iris-service"
    labels = {
      app = "iris-api"
    }
  }
  
  spec {
    type = "NodePort"  # Cambiado a NodePort para permitir acceso externo también
    
    selector = {
      app = "iris-api"
    }
    
    port {
      name        = "http"
      port        = 8000
      target_port = 8000
      node_port   = 30004  # Puerto externo opcional
    }
  }
}

