# ========================================
# OUTPUTS
# ========================================
# Información útil después del despliegue

output "mlflow_url" {
  description = "URL de acceso a MLflow"
  value       = "http://localhost:${var.mlflow_node_port}"
}

output "evidently_url" {
  description = "URL de acceso a Evidently"
  value       = "http://localhost:${var.evidently_node_port}"
}

output "jupyter_url" {
  description = "URL de acceso a Jupyter Lab"
  value       = "http://localhost:${var.workspace_node_port}"
}

output "iris_api_url" {
  description = "URL de acceso al Iris API"
  value       = "http://localhost:${var.iris_api_node_port}"
}

output "useful_commands" {
  description = "Comandos útiles"
  value = <<-EOT
    
    ========================================
    🎉 DESPLIEGUE COMPLETADO
    ========================================
    
    📊 URLs de Acceso:
    ------------------
    MLflow:       http://localhost:${var.mlflow_node_port}
    Evidently:    http://localhost:${var.evidently_node_port}
    Jupyter Lab:  http://localhost:${var.workspace_node_port}
    Iris API:     http://localhost:${var.iris_api_node_port}
    
    🔧 Comandos Útiles:
    -------------------
    # Ver todos los pods
    kubectl get pods
    
    # Ver servicios
    kubectl get services
    
    # Ver logs de un servicio
    kubectl logs -l app=iris-api --tail=50
    
    # Escalar el Iris API
    kubectl scale deployment iris-api --replicas=5
    
    # Reiniciar un deployment
    kubectl rollout restart deployment iris-api
    
    # Ejecutar comando en el workspace
    kubectl exec -it $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}') -- bash
    
    # Copiar notebooks al workspace (si es necesario)
    kubectl cp ../notebooks/01_simulacion.ipynb $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}'):/app/notebooks/
    
    📚 Próximos Pasos:
    ------------------
    1. Abre Jupyter Lab en tu navegador: http://localhost:${var.workspace_node_port}
    2. Navega a notebooks/01_simulacion.ipynb
    3. Ejecuta todas las celdas
    4. Revisa los resultados en MLflow y Evidently
    
    ========================================
  EOT
}
