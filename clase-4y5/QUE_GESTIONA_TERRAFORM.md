# 🏗️ ¿QUÉ GESTIONA TERRAFORM EN ESTA CLASE?

## 📦 Resumen Ejecutivo

Terraform gestiona **10 recursos de Kubernetes** dentro del cluster `mlops-cluster`:

```
├── 4 Deployments (pods + configuración)
├── 4 Services (networking)
└── 1 ConfigMap (configuración)
```

**NO gestiona:**
- ❌ El cluster de Kind (se crea manualmente)
- ❌ Las imágenes Docker (se construyen con `docker build`)
- ❌ Los notebooks (se copian con `kubectl cp`)

---

## 🎯 ¿Para Qué Sirve Terraform?

### **Permite Modificar Infraestructura en Vivo:**

```
Editas .tf → terraform plan → terraform apply → Kubernetes actualiza
```

**Sin downtime** ✅  
**Reproducible** ✅  
**Versionable** ✅  

---

## 📋 RECURSOS GESTIONADOS POR TERRAFORM

### **1. MLflow** (`infra/mlflow.tf`)

#### **Deployment:**
```terraform
kubernetes_deployment.mlflow
├── image: mlflow/mlflow:latest
├── replicas: 1
├── port: 5000
└── resources:
    ├── cpu: 250m - 500m
    └── memory: 512Mi - 1Gi
```

**¿Qué puedes cambiar?**
- ✅ Recursos (CPU/memoria)
- ✅ Variables de entorno
- ✅ Comandos de inicio

#### **Service:**
```terraform
kubernetes_service.mlflow
├── type: NodePort
├── port: 5000
└── nodePort: 30001
```

**¿Qué puedes cambiar?**
- ✅ Puerto NodePort (30001 → otro)
- ✅ Tipo de servicio (NodePort → ClusterIP)

---

### **2. Evidently** (`infra/evidently.tf`)

#### **ConfigMap:**
```terraform
kubernetes_config_map.evidently_config
└── config.yaml
    ├── service.port: 8000
    ├── workspace.path: /app/workspace
    └── projects: iris-monitoring
```

**¿Qué puedes cambiar?**
- ✅ Configuración completa de Evidently
- ✅ Proyectos de monitoreo
- ✅ Rutas de workspace

#### **Deployment:**
```terraform
kubernetes_deployment.evidently
├── image: evidently/evidently-service:latest
├── replicas: 1
├── port: 8000
└── resources:
    ├── cpu: 250m - 500m
    └── memory: 512Mi - 1Gi    ← PERFECTO PARA DEMO
```

**¿Qué puedes cambiar?**
- ✅ Recursos (CPU/memoria) ⭐ **DEMO 1**
- ✅ Configuración vía ConfigMap
- ✅ Variables de entorno

#### **Service:**
```terraform
kubernetes_service.evidently
├── type: NodePort
├── port: 8000
└── nodePort: 30002
```

---

### **3. Iris API** (`infra/iris_api.tf`)

#### **Deployment:**
```terraform
kubernetes_deployment.iris_api
├── image: iris-api:latest
├── replicas: 2    ← PERFECTO PARA DEMO DE ESCALADO
├── port: 8000
└── resources:
    ├── cpu: 100m - 200m
    └── memory: 128Mi - 256Mi
```

**¿Qué puedes cambiar?**
- ✅ Réplicas (2 → 4) ⭐ **DEMO 2**
- ✅ Recursos (CPU/memoria)
- ✅ Variables de entorno
- ✅ Estrategia de actualización

#### **Service:**
```terraform
kubernetes_service.iris
├── type: NodePort
├── port: 8000
└── nodePort: 30004
```

**¿Qué puedes cambiar?**
- ✅ Tipo de servicio (NodePort → ClusterIP para interno)
- ✅ Puerto externo

---

### **4. Workspace** (`infra/workspace.tf`)

#### **Deployment:**
```terraform
kubernetes_deployment.workspace
├── image: workspace:latest
├── replicas: 1
├── port: 8888
├── env:
│   ├── IRIS_API_URL: http://iris-service:8000
│   └── MLFLOW_URI: http://mlflow-service:5000
└── resources:
    ├── cpu: 250m - 500m
    └── memory: 256Mi - 512Mi
```

**¿Qué puedes cambiar?**
- ✅ Variables de entorno (URLs, configuración)
- ✅ Recursos (CPU/memoria)
- ✅ Comandos de inicio de Jupyter

#### **Service:**
```terraform
kubernetes_service.workspace
├── type: NodePort
├── port: 8888
└── nodePort: 30003
```

---

## 🎬 PRÁCTICAS SUGERIDAS POR DIFICULTAD

### **🟢 FÁCIL: Cambiar Recursos**

| Recurso | Archivo | Línea | Cambio Sugerido |
|---------|---------|-------|-----------------|
| Evidently Memoria | `evidently.tf` | 88 | 1Gi → 256Mi |
| MLflow CPU | `mlflow.tf` | 59 | 500m → 1000m |
| Workspace Memoria | `workspace.tf` | 86 | 512Mi → 1Gi |

**Comando:**
```bash
# Modificar el .tf
terraform plan
terraform apply
kubectl describe pod -l app=evidently | grep Limits -A 3
```

---

### **🟡 INTERMEDIO: Escalar Réplicas**

| Recurso | Archivo | Línea | Cambio Sugerido |
|---------|---------|-------|-----------------|
| Iris API | `iris_api.tf` | 11 | 2 → 4 réplicas |
| MLflow | `mlflow.tf` | 11 | 1 → 2 réplicas |

**Comando:**
```bash
# Modificar el .tf
terraform plan
terraform apply
kubectl get pods -l app=iris-api
# Debería ver 4 pods
```

**Bonus: Probar balanceo de carga (ver logs en tiempo real):**
```bash
# Terminal 1: Ver logs de todas las réplicas
kubectl logs -f -l app=iris-api --tail=0 --prefix

# Terminal 2: Hacer requests desde dentro del workspace
WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')
for i in {1..20}; do
  kubectl exec $WORKSPACE_POD -- curl -s http://iris-service:8000/health > /dev/null
  echo "Request $i enviado"
  sleep 0.3
done
```

---

### **🔴 AVANZADO: Cambiar Tipo de Servicio**

**Objetivo:** Hacer que Iris API sea solo interno (ClusterIP).

**Modificar `infra/iris_api.tf` líneas 90-105:**

**ANTES:**
```terraform
spec {
  type = "NodePort"
  
  selector = {
    app = "iris-api"
  }
  
  port {
    name        = "http"
    port        = 8000
    target_port = 8000
    node_port   = 30004
  }
}
```

**DESPUÉS:**
```terraform
spec {
  type = "ClusterIP"    # ← Cambio aquí
  
  selector = {
    app = "iris-api"
  }
  
  port {
    name        = "http"
    port        = 8000
    target_port = 8000
    # node_port eliminado - no se usa en ClusterIP
  }
}
```

**Aplicar:**
```bash
terraform plan
# Verás que el servicio se modifica

terraform apply
```

**Verificar:**
```bash
kubectl get service iris-service
# TYPE debería ser ClusterIP

# Ya NO puedes acceder desde localhost:30004
curl http://localhost:30004/health
# Error: Connection refused

# Pero SÍ desde dentro del cluster:
kubectl exec -it $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}') -- curl http://iris-service:8000/health
# ✅ Funciona
```

**📢 Concepto:** ClusterIP = solo acceso interno. NodePort = acceso externo.

---

## 🚫 ¿QUÉ NO PUEDES CAMBIAR CON TERRAFORM?

### **1. El Modelo en Iris API**

**¿Por qué?**  
El modelo está "cocinado" en la imagen Docker durante `docker build`.

**Para cambiar el modelo:**
```bash
# 1. Modificar train.py
# 2. Reconstruir imagen
cd app_iris
docker build -t iris-api:latest .

# 3. Recargar en Kind
kind load docker-image iris-api:latest --name mlops-cluster

# 4. Forzar recreación del pod
kubectl rollout restart deployment iris-api
```

**💡 En producción:** Usarías tags versionados (`iris-api:v2.0`) y actualizarías el `.tf`:
```terraform
image = "iris-api:v2.0"
```

---

### **2. El Clúster de Kind**

**¿Por qué?**  
El clúster se crea manualmente antes de Terraform:
```bash
kind create cluster --name mlops-cluster --config infra/kind-config.yaml
```

**Terraform solo gestiona recursos DENTRO del cluster.**

**💡 En producción (AWS EKS):**
```terraform
# Terraform SÍ crearía el cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  cluster_name = "mlops-prod"
  ...
}
```

---

### **3. Los Notebooks**

**¿Por qué?**  
Se copian manualmente con `kubectl cp` para que puedas editarlos sin reconstruir la imagen.

**Para actualizar notebooks:**
```bash
./scripts/copy-notebooks.sh
```

---

## 📊 MATRIZ DE CAMBIOS

| Cambio | ¿Requiere Terraform? | ¿Requiere Rebuild? | ¿Requiere Kind Reload? |
|--------|---------------------|-------------------|----------------------|
| **Memoria/CPU** | ✅ Sí | ❌ No | ❌ No |
| **Réplicas** | ✅ Sí | ❌ No | ❌ No |
| **Variables ENV** | ✅ Sí | ❌ No | ❌ No |
| **Puerto NodePort** | ✅ Sí | ❌ No | ❌ No |
| **ConfigMap** | ✅ Sí | ❌ No | ❌ No |
| **Código del Modelo** | ❌ No | ✅ Sí | ✅ Sí |
| **Dependencias Python** | ❌ No | ✅ Sí | ✅ Sí |
| **Notebooks** | ❌ No | ❌ No | ❌ No (usar kubectl cp) |

---

## 🎯 CONCEPTOS CLAVE

### **1. Separation of Concerns**

```
┌─────────────────────────────────────────┐
│ Nivel 1: Cluster (Kind)                 │  ← Manual / Externo a Terraform
│   kind create cluster                   │
├─────────────────────────────────────────┤
│ Nivel 2: Recursos K8s (Terraform)       │  ← Terraform gestiona aquí
│   Deployments, Services, ConfigMaps     │
├─────────────────────────────────────────┤
│ Nivel 3: Imágenes (Docker)              │  ← docker build + kind load
│   iris-api:latest, workspace:latest     │
├─────────────────────────────────────────┤
│ Nivel 4: Datos/Config (kubectl/scripts) │  ← kubectl cp, port-forward
│   Notebooks, logs, debugging            │
└─────────────────────────────────────────┘
```

---

### **2. Estado Deseado vs Estado Real**

```python
# Pseudocódigo de cómo funciona Terraform

estado_deseado = leer(".tf files")
estado_real = consultar("Kubernetes API")

diferencias = calcular_delta(estado_deseado, estado_real)

if diferencias:
    plan = generar_plan(diferencias)
    if usuario_aprueba(plan):
        aplicar_cambios(plan)
        guardar_estado("terraform.tfstate")
```

---

### **3. Rolling Updates**

```
┌─────────────────────────────────────────────────┐
│ terraform apply (cambiar memoria de Evidently)  │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Kubernetes ReplicaSet                           │
│                                                 │
│ 1. Crear pod nuevo con 256Mi                   │
│    Status: ContainerCreating                    │
│                                                 │
│ 2. Esperar health checks                        │
│    Status: Running (ready)                      │
│                                                 │
│ 3. Service empieza a enviar tráfico al nuevo   │
│                                                 │
│ 4. Terminar pod viejo                           │
│    Status: Terminating                          │
│                                                 │
│ 5. Limpiar recursos                             │
│    Status: Completed                            │
└─────────────────────────────────────────────────┘
```

**⏱️ Todo esto toma ~30 segundos.**  
**💡 Zero downtime garantizado.**

---

## 🎓 PARA LOS ALUMNOS

### **¿Cuándo Usar Terraform?**

✅ **Cambios planificados** - Escalar, modificar recursos, cambiar configuración  
✅ **Infraestructura reproducible** - Mismo código = mismo resultado  
✅ **Múltiples ambientes** - dev, staging, prod con el mismo código  
✅ **Auditoría** - Git history muestra quién cambió qué  

### **¿Cuándo NO Usar Terraform?**

❌ **Debugging rápido** - Usa `kubectl` directo  
❌ **Operaciones urgentes** - `kubectl scale`, `kubectl delete`  
❌ **Inspección de estado** - `kubectl get`, `kubectl describe`  

**Regla de oro:**
> Usa `kubectl` para **leer** y **debuggear**.  
> Usa `terraform` para **crear** y **modificar**.

---

## 📚 Comandos de Referencia Rápida

```bash
# Ver qué recursos gestiona Terraform
terraform state list

# Ver detalle de un recurso
terraform state show kubernetes_deployment.evidently

# Ver outputs
terraform output

# Sincronizar estado con cluster
terraform refresh

# Importar recurso existente (avanzado)
terraform import kubernetes_deployment.mlflow default/mlflow

# Ver graph de dependencias
terraform graph | dot -Tpng > graph.png
```

---

¡Ahora tienes control total sobre tu infraestructura! 🚀

