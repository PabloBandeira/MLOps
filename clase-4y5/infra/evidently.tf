# ========================================
# EVIDENTLY SERVICE
# ========================================
# Deployment, ConfigMap y Service para Evidently

# ConfigMap para la configuración de Evidently
resource "kubernetes_config_map" "evidently_config" {
  
  metadata {
    name = "evidently-config"
  }
  
  data = {
    "config.yaml" = <<-EOT
      service:
        port: 8000
        
      workspace:
        path: /app/workspace
        
      projects:
        - name: iris-monitoring
          description: "Monitoreo del modelo Iris"
    EOT
  }
}

# Deployment de Evidently
resource "kubernetes_deployment" "evidently" {
  depends_on = [kubernetes_config_map.evidently_config]
  
  metadata {
    name = "evidently"
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
          image = "evidently/evidently-service:latest"
          
          port {
            container_port = 8000
            name           = "http"
          }
          
          env {
            name  = "WORKSPACE"
            value = "/app/workspace"
          }
          
          # Montar ConfigMap
          volume_mount {
            name       = "config"
            mount_path = "/app/config.yaml"
            sub_path   = "config.yaml"
          }
          
          # Health check          
          # Health checks deshabilitados temporalmente
          # Evidently service no expone un endpoint /health consistente
          
          resources {
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
        
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.evidently_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Service de Evidently (NodePort para acceso externo)
resource "kubernetes_service" "evidently" {
  depends_on = [kubernetes_deployment.evidently]
  
  metadata {
    name = "evidently-service"
    labels = {
      app = "evidently"
    }
  }
  
  spec {
    type = "NodePort"
    
    selector = {
      app = "evidently"
    }
    
    port {
      name        = "http"
      port        = 8000
      target_port = 8000
      node_port   = 30002
    }
  }
}

