# ========================================
# CLÚSTER KIND
# ========================================
# Crea el clúster local de Kubernetes usando Kind

resource "kind_cluster" "mlops" {
  name            = "mlops-cluster"
  wait_for_ready  = true
  
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    node {
      role = "control-plane"
      
      # Port mappings para exponer servicios
      extra_port_mappings {
        container_port = 30001
        host_port      = 30001
        protocol       = "TCP"
      }
      
      extra_port_mappings {
        container_port = 30002
        host_port      = 30002
        protocol       = "TCP"
      }
      
      extra_port_mappings {
        container_port = 30003
        host_port      = 30003
        protocol       = "TCP"
      }
      
      extra_port_mappings {
        container_port = 30004
        host_port      = 30004
        protocol       = "TCP"
      }
    }
  }
}

