# 🚀 Referencia Rápida - Clase 4

## ⚡ Setup Automático

```bash
# Ejecutar todo el proceso de despliegue automáticamente
./scripts/setup.sh
```

---

## 📝 Setup Manual (Paso a Paso)

### 1. Construir Imágenes

```bash
# Iris API (con modelo entrenado en build)
cd app_iris
docker build -t iris-api:latest .
cd ..

# Workspace Jupyter
cd app_workspace
docker build -t workspace:latest .
cd ..
```

### 2. Crear Clúster Kind

```bash
kind create cluster --name mlops-cluster --config infra/kind-config.yaml
```

### 3. Cargar Imágenes al Clúster

```bash
kind load docker-image iris-api:latest --name mlops-cluster
kind load docker-image workspace:latest --name mlops-cluster
```

### 4. Desplegar con Terraform

```bash
cd infra
terraform init
terraform apply
cd ..
```

### 5. Esperar a que los Pods estén Listos

```bash
kubectl get pods -w
# Presiona Ctrl+C cuando todos estén en Running
```

---

## 🌐 URLs de Acceso

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **MLflow** | http://localhost:30001 | Tracking de experimentos |
| **Evidently** | http://localhost:30002 | Detección de drift |
| **Jupyter Lab** | http://localhost:30003 | Entorno del alumno |
| **Iris API** | http://localhost:30004 | API de predicción |

---

## 🔧 Comandos Útiles de Kubernetes

### Ver Estado

```bash
# Ver todos los pods
kubectl get pods

# Ver servicios
kubectl get services

# Ver todos los recursos
kubectl get all

# Describir un pod
kubectl describe pod <POD_NAME>
```

### Logs

```bash
# Ver logs de un pod específico
kubectl logs <POD_NAME>

# Ver logs de todos los pods de un servicio
kubectl logs -l app=iris-api

# Seguir logs en tiempo real
kubectl logs -f <POD_NAME>

# Ver últimas N líneas
kubectl logs <POD_NAME> --tail=50
```

### Escalar Deployments

```bash
# Escalar el Iris API a 5 réplicas
kubectl scale deployment iris-api --replicas=5

# Verificar el escalamiento
kubectl get deployment iris-api
```

### Reiniciar Deployments

```bash
# Reiniciar un deployment (rolling restart)
kubectl rollout restart deployment iris-api

# Ver estado del rollout
kubectl rollout status deployment iris-api
```

### Ejecutar Comandos en Pods

```bash
# Obtener shell en un pod
kubectl exec -it <POD_NAME> -- /bin/bash

# Ejecutar comando específico
kubectl exec <POD_NAME> -- ls -la /app

# Ejecutar en el workspace
kubectl exec -it $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}') -- bash
```

### Copiar Archivos

```bash
# Copiar archivo local al pod
kubectl cp ./local_file.txt <POD_NAME>:/app/remote_file.txt

# Copiar archivo del pod a local
kubectl cp <POD_NAME>:/app/remote_file.txt ./local_file.txt

# Copiar notebook al workspace
kubectl cp notebooks/01_simulacion.ipynb $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}'):/app/notebooks/
```

### Port Forwarding (Alternativa a NodePort)

```bash
# Forward de puerto de MLflow
kubectl port-forward service/mlflow-service 5000:5000

# Forward de puerto de Jupyter
kubectl port-forward service/workspace-service 8888:8888

# En otra terminal, accede a http://localhost:5000
```

---

## 🐛 Troubleshooting

### Problema: Pod en estado `Pending` o `ImagePullBackOff`

```bash
# Ver descripción del pod
kubectl describe pod <POD_NAME>

# Recargar imagen
kind load docker-image iris-api:latest --name mlops-cluster

# Reiniciar deployment
kubectl rollout restart deployment iris-api
```

### Problema: No puedo acceder a los servicios

```bash
# Verificar que el servicio esté en NodePort
kubectl get service mlflow-service

# Verificar port mappings del clúster
docker ps | grep mlops-cluster

# Usar port-forward como alternativa
kubectl port-forward service/mlflow-service 5000:5000
```

### Problema: El pod crashea constantemente

```bash
# Ver logs del pod
kubectl logs <POD_NAME> --previous

# Ver eventos del clúster
kubectl get events --sort-by='.lastTimestamp'

# Verificar recursos
kubectl top pods
```

### Problema: Jupyter no muestra los notebooks

```bash
# Copiar notebooks manualmente
WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')
kubectl cp notebooks/01_simulacion.ipynb $WORKSPACE_POD:/app/notebooks/

# Entrar al pod y verificar
kubectl exec -it $WORKSPACE_POD -- ls -la /app/notebooks/
```

---

## 🔍 Verificar que Todo Funciona

### Test desde tu laptop

```bash
# Test MLflow
curl http://localhost:30001/health

# Test Iris API
curl http://localhost:30004/health

# Test predicción
curl -X POST "http://localhost:30004/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

### Test desde dentro del clúster (DNS interno)

```bash
# Entrar al workspace
kubectl exec -it $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}') -- bash

# Dentro del pod:
curl http://mlflow-service:5000/health
curl http://iris-service:8000/health
curl http://evidently-service:8000/health
```

---

## 🧹 Limpieza

### Limpieza Automática

```bash
./scripts/cleanup.sh
```

### Limpieza Manual

```bash
# 1. Destruir recursos de Terraform
cd infra
terraform destroy
cd ..

# 2. Eliminar clúster Kind
kind delete cluster --name mlops-cluster

# 3. (Opcional) Eliminar imágenes Docker
docker rmi iris-api:latest workspace:latest
```

---

## 📊 Terraform Específico

```bash
# Ver plan sin aplicar
terraform plan

# Aplicar cambios específicos
terraform apply -target=kubernetes_deployment.iris_api

# Ver estado actual
terraform show

# Ver outputs
terraform output

# Formatear archivos .tf
terraform fmt

# Validar configuración
terraform validate
```

---

## 🎯 Comandos Kind Específicos

```bash
# Listar clústeres
kind get clusters

# Ver nodos del clúster
kind get nodes --name mlops-cluster

# Obtener kubeconfig
kind get kubeconfig --name mlops-cluster

# Ver logs del nodo
docker logs mlops-cluster-control-plane

# Eliminar clúster
kind delete cluster --name mlops-cluster
```

---

## 📈 Monitoreo y Métricas

```bash
# Ver uso de recursos (requiere metrics-server)
kubectl top nodes
kubectl top pods

# Ver eventos en tiempo real
kubectl get events --watch

# Ver estado de los deployments
kubectl get deployments -o wide

# Ver endpoints de los servicios
kubectl get endpoints
```

---

## 🔄 Actualizar Código

Si modificas el código de la API o del workspace:

```bash
# 1. Reconstruir imagen
cd app_iris
docker build -t iris-api:latest .
cd ..

# 2. Recargar en Kind
kind load docker-image iris-api:latest --name mlops-cluster

# 3. Reiniciar deployment (fuerza pull de nueva imagen)
kubectl rollout restart deployment iris-api

# 4. Verificar que se actualizó
kubectl get pods -w
```

---

## 💡 Tips

1. **Usa aliases** para comandos frecuentes:
   ```bash
   alias k='kubectl'
   alias kgp='kubectl get pods'
   alias kgs='kubectl get services'
   alias kl='kubectl logs'
   ```

2. **Habilita autocompletado** de kubectl:
   ```bash
   source <(kubectl completion bash)  # Para bash
   source <(kubectl completion zsh)   # Para zsh
   ```

3. **Usa k9s** para una interfaz TUI:
   ```bash
   brew install k9s  # macOS
   k9s
   ```

4. **Cambia de contexto** si tienes múltiples clústeres:
   ```bash
   kubectl config get-contexts
   kubectl config use-context kind-mlops-cluster
   ```

---

## 📚 Recursos Adicionales

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Kind Docs](https://kind.sigs.k8s.io/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

¡Feliz aprendizaje! 🎉

