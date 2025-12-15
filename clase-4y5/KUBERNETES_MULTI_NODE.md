# 🔀 KUBERNETES MULTI-NODE - Migración de 1 a 2+ Nodos

## 📋 Objetivo

Migrar el cluster de Kind de **1 nodo** (control-plane único) a **2 nodos workers** para demostrar:
- ✅ Distribución real de pods entre nodos
- ✅ Alta disponibilidad
- ✅ Resiliencia ante fallos
- ✅ Comportamiento de producción

---

## 🎯 ¿Por Qué Usar Múltiples Nodos?

### **Configuración Actual (1 Nodo):**

```
┌─────────────────────────────────────┐
│  Control-Plane (mlops-cluster)      │
│  TODOS los pods en el mismo nodo    │
│                                     │
│  📦 MLflow                          │
│  📦 Evidently                       │
│  📦 Iris API x4                     │
│  📦 Workspace                       │
└─────────────────────────────────────┘
```

**Limitaciones:**
- ⚠️ Si el nodo cae, TODO el sistema cae
- ⚠️ No hay distribución real de carga
- ⚠️ No se puede demostrar resiliencia

---

### **Configuración Multi-Nodo (2 Workers):**

```
     ┌──────────────────────┐
     │   Control-Plane      │
     │   (Gestión del       │
     │    cluster)          │
     └──────────────────────┘
              │
        ┌─────┴─────┐
        ↓           ↓
┌──────────────┐ ┌──────────────┐
│  Worker 1    │ │  Worker 2    │
│              │ │              │
│ 📦 MLflow    │ │ 📦 Iris-1   │
│ 📦 Evidently │ │ 📦 Iris-2   │
│ 📦 Workspace │ │ 📦 Iris-3   │
│              │ │ 📦 Iris-4   │
└──────────────┘ └──────────────┘
```

**Ventajas:**
- ✅ Alta disponibilidad real
- ✅ Distribución automática de pods
- ✅ Si un worker cae, Kubernetes reubica pods
- ✅ Simula entorno de producción

---

## ⚠️ IMPORTANTE: Ajuste de Recursos

Al usar múltiples nodos, **cada nodo consume memoria base** (~500MB por nodo).

**Estrategia:** Reducir los límites de memoria de los servicios para que quepan en 2 nodos.

| Servicio | Memoria Actual | Memoria Reducida |
|----------|---------------|------------------|
| **MLflow** | 1Gi | 256Mi |
| **Evidently** | 1Gi | 256Mi |
| **Iris API** | 256Mi | 128Mi |
| **Workspace** | 512Mi | 256Mi |

---

## 🚀 PASO A PASO: Migración a Multi-Nodo

### **PASO 1: Limpiar el Cluster Actual**

Primero, elimina todo lo que desplegaste con Terraform.

```bash
cd clase-4/infra

# Destruir recursos de Terraform
terraform destroy
# Escribir: yes
```

**Espera a que termine (30-60 segundos).**

Verifica que se eliminaron todos los recursos:

```bash
kubectl get all
# Debería mostrar solo el servicio "kubernetes" (default)
```

---

### **PASO 2: Eliminar el Cluster de Kind**

```bash
# Eliminar el cluster actual
kind delete cluster --name mlops-cluster
```

**Output esperado:**
```
Deleting cluster "mlops-cluster" ...
```

Verifica que se eliminó:

```bash
kind get clusters
# No debería mostrar "mlops-cluster"

docker ps
# No deberías ver contenedores de mlops-cluster
```

---

### **PASO 3: Modificar `kind-config.yaml` para 2 Workers**

Edita el archivo `infra/kind-config.yaml`:

**ANTES (1 nodo):**
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30001
        hostPort: 30001
        protocol: TCP
      - containerPort: 30002
        hostPort: 30002
        protocol: TCP
      - containerPort: 30003
        hostPort: 30003
        protocol: TCP
      - containerPort: 30004
        hostPort: 30004
        protocol: TCP
```

**DESPUÉS (1 control-plane + 2 workers):**
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  # Control-Plane: Gestiona el cluster (NO corre aplicaciones)
  - role: control-plane
    extraPortMappings:
      - containerPort: 30001
        hostPort: 30001
        protocol: TCP
      - containerPort: 30002
        hostPort: 30002
        protocol: TCP
      - containerPort: 30003
        hostPort: 30003
        protocol: TCP
      - containerPort: 30004
        hostPort: 30004
        protocol: TCP
  
  # Worker 1: Corre aplicaciones
  - role: worker
  
  # Worker 2: Corre aplicaciones
  - role: worker
```

**💡 Nota:** Los `extraPortMappings` solo se configuran en el control-plane, ya que Kind redirige el tráfico automáticamente a los workers.

---

### **PASO 4: Reducir Límites de Memoria en Terraform**

Edita los siguientes archivos de Terraform para reducir el consumo de memoria:

#### **A. MLflow (`infra/mlflow.tf`):**

**Buscar líneas 57-65, cambiar:**
```terraform
resources {
  requests = {
    cpu    = "250m"
    memory = "256Mi"    # ← Reducido de 512Mi
  }
  limits = {
    cpu    = "500m"
    memory = "512Mi"    # ← Reducido de 1Gi
  }
}
```

---

#### **B. Evidently (`infra/evidently.tf`):**

**Buscar líneas 81-90, cambiar:**
```terraform
resources {
  requests = {
    cpu    = "250m"
    memory = "128Mi"    # ← Reducido de 512Mi
  }
  limits = {
    cpu    = "500m"
    memory = "256Mi"    # ← Reducido de 1Gi
  }
}
```

---

#### **C. Iris API (`infra/iris_api.tf`):**

**Buscar líneas 72-81, cambiar:**
```terraform
resources {
  requests = {
    cpu    = "100m"
    memory = "64Mi"     # ← Reducido de 128Mi
  }
  limits = {
    cpu    = "200m"
    memory = "128Mi"    # ← Sin cambio (ya era 128Mi o cambiar a 128Mi si era 256Mi)
  }
}
```

---

#### **D. Workspace (`infra/workspace.tf`):**

**Buscar líneas 84-93, cambiar:**
```terraform
resources {
  requests = {
    cpu    = "250m"
    memory = "128Mi"    # ← Reducido de 256Mi
  }
  limits = {
    cpu    = "500m"
    memory = "256Mi"    # ← Reducido de 512Mi
  }
}
```

---

### **PASO 5: Crear el Cluster Multi-Nodo**

```bash
kind create cluster --name mlops-cluster --config infra/kind-config.yaml
```

**Output esperado:**
```
Creating cluster "mlops-cluster" ...
 ✓ Ensuring node image (kindest/node:v1.27.3)
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-mlops-cluster"
```

**Tiempo estimado:** 1-2 minutos

---

### **PASO 6: Verificar los Nodos**

```bash
kubectl get nodes
```

**Output esperado:**
```
NAME                         STATUS   ROLES           AGE   VERSION
mlops-cluster-control-plane  Ready    control-plane   60s   v1.27.3
mlops-cluster-worker         Ready    <none>          40s   v1.27.3
mlops-cluster-worker2        Ready    <none>          40s   v1.27.3
```

✅ **Deberías ver 3 nodos: 1 control-plane + 2 workers**

---

### **PASO 7: Cargar Imágenes Docker al Cluster**

Como recreaste el cluster, debes volver a cargar las imágenes:

```bash
# Cargar imagen de Iris API
kind load docker-image iris-api:latest --name mlops-cluster

# Cargar imagen de Workspace
kind load docker-image workspace:latest --name mlops-cluster
```

**Verificar:**
```bash
docker exec -it mlops-cluster-control-plane crictl images | grep -E "iris-api|workspace"
```

Deberías ver ambas imágenes listadas.

---

### **PASO 8: Desplegar con Terraform**

```bash
cd infra

# Inicializar Terraform (si es necesario)
terraform init

# Ver el plan
terraform plan

# Aplicar
terraform apply
# Escribir: yes
```

**Tiempo estimado:** 2-3 minutos

---

### **PASO 9: Verificar Distribución de Pods**

Este es el comando **más importante** para ver la magia de multi-nodo:

```bash
kubectl get pods -o wide
```

**Output esperado:**
```
NAME                         READY   STATUS    NODE                      AGE
evidently-xxx                1/1     Running   mlops-cluster-worker      30s
iris-api-5b94b7cbd7-2vjtn    1/1     Running   mlops-cluster-worker      30s
iris-api-5b94b7cbd7-c5hzp    1/1     Running   mlops-cluster-worker2     30s  ← Nodo diferente!
iris-api-5b94b7cbd7-q7thv    1/1     Running   mlops-cluster-worker      30s
iris-api-5b94b7cbd7-x5tpq    1/1     Running   mlops-cluster-worker2     30s  ← Nodo diferente!
mlflow-xxx                   1/1     Running   mlops-cluster-worker2     30s
workspace-xxx                1/1     Running   mlops-cluster-worker      30s
```

**🎯 Observa la columna `NODE`:**
- Algunos pods están en `mlops-cluster-worker`
- Otros están en `mlops-cluster-worker2`
- **Kubernetes distribuye automáticamente** para balancear la carga

---

### **PASO 10: Copiar Notebooks al Workspace**

```bash
cd ..  # Regresar al directorio raíz
./scripts/copy-notebooks.sh
```

---

### **PASO 11: Verificar Servicios**

```bash
# Verificar que todos los pods estén Running
kubectl get pods

# Verificar servicios
kubectl get services

# Acceder a Jupyter
open http://localhost:30003
```

---

## 🧪 DEMOS PARA MOSTRAR A LOS ALUMNOS

### **DEMO 1: Ver Distribución de Pods**

```bash
kubectl get pods -o wide
```

**Mostrar:**
- Columna `NODE` - Diferentes nodos
- Kubernetes distribuye automáticamente
- No necesitas configurar nada extra

---

### **DEMO 2: Ver Recursos de Cada Nodo**

**⚠️ Prerequisito:** Primero debes instalar Metrics Server (Kind no lo incluye por defecto).

#### **Paso 1: Instalar Metrics Server**

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**Verificar que se desplegó:**
```bash
kubectl get deployment metrics-server -n kube-system
```

**Output esperado:**
```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           10s
```

---

#### **Paso 2: Parchear para Kind (Deshabilitar TLS Validation)**

Kind usa certificados self-signed, debemos deshabilitar la validación TLS:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'
```

**Esperar 30 segundos a que el pod se reinicie:**
```bash
sleep 30
```

---

#### **Paso 3: Ver Uso de Recursos por Nodo**

Ahora sí puedes usar `kubectl top nodes`:

```bash
kubectl top nodes
```

**Output esperado:**
```
NAME                         CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
mlops-cluster-control-plane  150m         7%     400Mi           10%
mlops-cluster-worker         300m         15%    800Mi           20%
mlops-cluster-worker2        280m         14%    750Mi           19%
```

**💡 Muestra:** Los workers tienen más carga que el control-plane (como debe ser).

**También puedes ver recursos por pod:**
```bash
kubectl top pods
```

**Output esperado:**
```
NAME                         CPU(cores)   MEMORY(bytes)
evidently-xxx                10m          180Mi
iris-api-xxx-1               5m           80Mi
iris-api-xxx-2               5m           85Mi
mlflow-xxx                   15m          350Mi
workspace-xxx                20m          200Mi
```

---

### **DEMO 3: Simular Fallo de Nodo (AVANZADO)**

**⚠️ Advertencia:** Esta demo es opcional y solo para alumnos avanzados.

```bash
# 1. Ver distribución actual
kubectl get pods -o wide

# 2. Identificar un worker (ejemplo: worker2)
# 3. "Apagar" el nodo (simular fallo de hardware)
docker stop mlops-cluster-worker2

# 4. Esperar 1-2 minutos
sleep 120

# 5. Ver qué pasó
kubectl get nodes
# worker2 debería estar "NotReady"

kubectl get pods -o wide
# Los pods que estaban en worker2 están en "Terminating" o "Pending"
# Kubernetes intenta recrearlos en worker1
```

**💡 Concepto:** Kubernetes detecta el fallo y reubica automáticamente los pods.

**Revertir:**
```bash
docker start mlops-cluster-worker2
# Esperar 30 seg
kubectl get nodes
# worker2 vuelve a "Ready"
```

---

### **DEMO 4: Forzar Pods a Nodos Específicos (Node Affinity)**

**Opcional - Concepto Avanzado**

Puedes agregar `nodeSelector` a un deployment para forzar que un pod corra en un nodo específico.

**Ejemplo:** Forzar Workspace a correr en worker1:

```terraform
# En workspace.tf, agregar dentro de spec.template.spec:
node_selector = {
  "kubernetes.io/hostname" = "mlops-cluster-worker"
}
```

Luego:
```bash
terraform apply
kubectl get pods -o wide
# workspace-xxx SIEMPRE estará en worker
```

---

## 📊 COMPARACIÓN: 1 Nodo vs Multi-Nodo

| Aspecto | 1 Nodo | 2 Workers |
|---------|--------|-----------|
| **Nodos totales** | 1 (control-plane) | 3 (1 CP + 2 workers) |
| **Distribución real** | ❌ Todos en el mismo | ✅ Distribuidos |
| **Alta disponibilidad** | ❌ Si cae, TODO cae | ✅ Parcial (algunos pods sobreviven) |
| **Memoria usada** | ~2GB | ~3-4GB |
| **Tiempo de setup** | 30 seg | 1-2 min |
| **Realismo** | Dev | Producción |
| **Demos posibles** | Básicas | Avanzadas (resiliencia) |

---

## 🔧 TROUBLESHOOTING

### **Problema 1: Pods en `Pending`**

**Síntoma:**
```bash
kubectl get pods
NAME              READY   STATUS    RESTARTS   AGE
iris-api-xxx      0/1     Pending   0          2m
```

**Causa:** No hay recursos suficientes en los nodos.

**Diagnóstico:**
```bash
kubectl describe pod iris-api-xxx
# Ver sección "Events"
```

**Solución:**
- Reducir aún más los límites de memoria en los `.tf`
- O agregar un tercer worker

---

### **Problema 2: Nodo en `NotReady`**

**Síntoma:**
```bash
kubectl get nodes
NAME                 STATUS     ROLES    AGE
mlops-cluster-worker NotReady   <none>   5m
```

**Causa:** El contenedor Docker del nodo puede estar detenido.

**Solución:**
```bash
docker ps -a | grep mlops-cluster
docker start mlops-cluster-worker
```

---

### **Problema 3: Imágenes no encontradas**

**Síntoma:**
```bash
kubectl describe pod iris-api-xxx
# Events: Failed to pull image "iris-api:latest"
```

**Causa:** Olvidaste cargar las imágenes al cluster nuevo.

**Solución:**
```bash
kind load docker-image iris-api:latest --name mlops-cluster
kind load docker-image workspace:latest --name mlops-cluster
```

---

## 🎓 CONCEPTOS CLAVE

### **1. Control-Plane vs Worker**

**Control-Plane:**
- Gestiona el cluster (API server, scheduler, controller)
- **NO corre aplicaciones** (por defecto)
- Similar al "cerebro" del cluster

**Worker:**
- Corre las aplicaciones (pods)
- Ejecuta los contenedores
- Similar a los "músculos" del cluster

---

### **2. Scheduler de Kubernetes**

Kubernetes decide automáticamente en qué nodo colocar cada pod basándose en:
- Recursos disponibles (CPU, memoria)
- Affinity/Anti-affinity rules
- Taints y tolerations
- Balanceo de carga

**No necesitas configurar nada**, Kubernetes lo hace solo.

---

### **3. Alta Disponibilidad (HA)**

**Con 1 nodo:**
- Si el nodo cae → TODO el sistema cae
- No hay redundancia

**Con 2+ nodos:**
- Si un nodo cae → Algunos pods sobreviven
- Kubernetes reubica los pods caídos en otros nodos
- Redundancia parcial

**Para HA completa (producción):**
- 3+ control-planes (para el plano de control)
- 3+ workers (para aplicaciones)
- Réplicas de servicios críticos en diferentes nodos

---

## 📚 COMANDOS DE REFERENCIA RÁPIDA

### **Ver nodos:**
```bash
kubectl get nodes
kubectl describe node mlops-cluster-worker
kubectl top nodes  # Uso de CPU/memoria por nodo
```

### **Ver distribución de pods:**
```bash
kubectl get pods -o wide
kubectl get pods -o wide --sort-by=.spec.nodeName
```

### **Ver recursos por nodo:**
```bash
kubectl describe node mlops-cluster-worker | grep -A 5 "Allocated resources"
```

### **Cordonar un nodo (evitar que reciba pods nuevos):**
```bash
kubectl cordon mlops-cluster-worker2
# Ahora NO se crearán pods nuevos en worker2

kubectl uncordon mlops-cluster-worker2
# Volver a permitir pods
```

### **Drenar un nodo (mover todos los pods a otros nodos):**
```bash
kubectl drain mlops-cluster-worker2 --ignore-daemonsets --delete-emptydir-data
# Mueve todos los pods de worker2 a otros nodos
```

---

## 🚀 RESUMEN DE CAMBIOS

### **Archivos Modificados:**

1. ✅ `infra/kind-config.yaml` - Agregar 2 workers
2. ✅ `infra/mlflow.tf` - Reducir memoria a 512Mi
3. ✅ `infra/evidently.tf` - Reducir memoria a 256Mi
4. ✅ `infra/iris_api.tf` - Reducir memoria a 128Mi
5. ✅ `infra/workspace.tf` - Reducir memoria a 256Mi

### **Comandos Ejecutados:**

```bash
# Limpiar
terraform destroy
kind delete cluster --name mlops-cluster

# Modificar archivos (ver arriba)

# Recrear
kind create cluster --name mlops-cluster --config infra/kind-config.yaml
kind load docker-image iris-api:latest --name mlops-cluster
kind load docker-image workspace:latest --name mlops-cluster

# Desplegar
cd infra
terraform apply

# Verificar
kubectl get nodes
kubectl get pods -o wide
```

---

## ✅ CHECKLIST FINAL

- [ ] Cluster eliminado con `kind delete cluster`
- [ ] `kind-config.yaml` modificado (2 workers)
- [ ] Límites de memoria reducidos en 4 archivos `.tf`
- [ ] Cluster recreado con 3 nodos (1 CP + 2 workers)
- [ ] Imágenes cargadas con `kind load`
- [ ] Terraform aplicado exitosamente
- [ ] Pods distribuidos en ambos workers
- [ ] Notebooks copiados al workspace
- [ ] Jupyter accesible en `localhost:30003`

---

## 🎯 SIGUIENTE PASO

Una vez que tengas el cluster multi-nodo funcionando, ejecuta el notebook `01_simulacion.ipynb` para verificar que todo funciona correctamente.

El notebook debería funcionar **igual que antes**, pero ahora sabes que los pods están distribuidos en múltiples nodos. 🚀

---

¡Éxito con la migración a multi-nodo! 💪

