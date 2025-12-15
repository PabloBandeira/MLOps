# 🏗️ Arquitectura de la Clase 4: MLOps en Kubernetes

## 📊 Resumen Ejecutivo

### **Clúster Desplegado:**
- **1 nodo único** (control-plane + worker)
- **Tipo:** Kind (Kubernetes in Docker)
- **Nombre:** `mlops-cluster`
- **Total de Pods:** 5 pods (6 con las 2 réplicas del Iris API)
- **Namespace:** `default`

---

## 🎯 Arquitectura del Clúster Actual (Single Node)

### **Vista General:**

```
┌─────────────────────────────────────────────┐
│   mlops-cluster-control-plane (1 nodo)     │
│   Rol: Control Plane + Worker              │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │      Namespace: default             │  │
│   │                                     │  │
│   │  📦 Pod: mlflow-xxx        (1)     │  │
│   │  📦 Pod: evidently-xxx     (1)     │  │
│   │  📦 Pod: iris-api-xxx      (2)     │  │
│   │  📦 Pod: workspace-xxx     (1)     │  │
│   │                                     │  │
│   │  Total: 5 pods                      │  │
│   └─────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Nota importante:** En Kind, el nodo **es un contenedor Docker** corriendo en tu máquina. Dentro de ese contenedor Docker corre Kubernetes, y dentro de Kubernetes corren tus pods.

---

## 🔍 Desglose por Componente

### **1. MLflow Server** 📊

```yaml
Deployment: mlflow
Réplicas: 1
Imagen: ghcr.io/mlflow/mlflow:v2.10.0
Puerto interno: 5000
NodePort: 30001
Recursos:
  - CPU: 250m (request) / 500m (limit)
  - Memory: 512Mi (request) / 1Gi (limit)
```

**Función:**
- Tracking de experimentos
- Registro de métricas y parámetros
- Almacenamiento de artifacts

**Acceso:**
- Interno: `http://mlflow-service:5000`
- Externo: `http://localhost:30001`

---

### **2. Evidently Service** 🔍

```yaml
Deployment: evidently
Réplicas: 1
Imagen: evidently/evidently-service:latest
Puerto interno: 8000
NodePort: 30002
Recursos:
  - CPU: 250m (request) / 500m (limit)
  - Memory: 512Mi (request) / 1Gi (limit)
ConfigMap: evidently-config (montado)
```

**Función:**
- Detección de data drift
- Análisis de calidad de datos
- Generación de reportes HTML

**Acceso:**
- Interno: `http://evidently-service:8000`
- Externo: `http://localhost:30002`

---

### **3. Iris API (Modelo de Inferencia)** 🌸

```yaml
Deployment: iris-api
Réplicas: 2  ← ¡Alta disponibilidad!
Imagen: iris-api:latest (custom)
Puerto interno: 8000
NodePort: 30004
Recursos:
  - CPU: 100m (request) / 500m (limit)
  - Memory: 256Mi (request) / 512Mi (limit)
```

**Función:**
- API REST de inferencia
- Modelo "cocinado" en la imagen (patrón inmutable)
- Clasificación de flores Iris
- Load balancing automático entre 2 réplicas

**Endpoints:**
- `GET /health` - Health check
- `GET /info` - Información del modelo
- `POST /predict` - Predicciones
- `GET /metrics` - Métricas del servicio

**Acceso:**
- Interno: `http://iris-service:8000`
- Externo: `http://localhost:30004`

**¿Por qué 2 réplicas?**
- ✅ Alta disponibilidad (si una falla, la otra responde)
- ✅ Load balancing (distribuye carga automáticamente)
- ✅ Zero-downtime deployments (rolling updates)

---

### **4. Workspace (JupyterLab)** 💻

```yaml
Deployment: workspace
Réplicas: 1
Imagen: workspace:latest (custom)
Puerto interno: 8888
NodePort: 30003
Recursos:
  - CPU: 250m (request) / 1000m (limit)
  - Memory: 512Mi (request) / 2Gi (limit)
Variables de entorno:
  - MLFLOW_TRACKING_URI
  - EVIDENTLY_SERVICE_URL
  - IRIS_API_URI
  - IRIS_API_URL
```

**Función:**
- Entorno de desarrollo para estudiantes
- JupyterLab con todas las librerías pre-instaladas
- Sin necesidad de instalación local
- Notebooks incluidos

**Librerías instaladas:**
- `jupyterlab`, `pandas`, `numpy`, `requests`
- `mlflow` (cliente), `evidently`, `scikit-learn`
- `matplotlib`, `seaborn`
- `pydantic==1.10.13` (compatible)

**Acceso:**
- Interno: `http://workspace-service:8888`
- Externo: `http://localhost:30003`

---

## 🌐 Networking: Services

| Service | Type | ClusterIP | NodePort | Target |
|---------|------|-----------|----------|--------|
| **mlflow-service** | NodePort | 10.96.144.231 | 30001 | mlflow:5000 |
| **evidently-service** | NodePort | 10.96.224.227 | 30002 | evidently:8000 |
| **iris-service** | NodePort | 10.96.237.44 | 30004 | iris-api:8000 |
| **workspace-service** | NodePort | 10.96.99.69 | 30003 | workspace:8888 |
| **kubernetes** | ClusterIP | 10.96.0.1 | - | API Server |

---

## 🔌 Port Mappings (Kind → Host)

```
Docker Container (Kind Node)     →     Tu Máquina (localhost)
├─ 30001 (MLflow)               →     30001
├─ 30002 (Evidently)            →     30002
├─ 30003 (JupyterLab)           →     30003
└─ 30004 (Iris API)             →     30004
```

**¿Cómo funciona esto?**

1. **Nivel 1:** Tus pods corren en el nodo de Kind
2. **Nivel 2:** Kind es un contenedor Docker
3. **Nivel 3:** Docker mapea los puertos al host

```
localhost:30001 → Docker:30001 → Kind Node:30001 → Service:5000 → Pod:5000
```

---

## 📦 Total de Recursos

### **Pods Desplegados:**
```
1 × MLflow      = 1 pod
1 × Evidently   = 1 pod
2 × Iris API    = 2 pods  ← Load balanced
1 × Workspace   = 1 pod
─────────────────────────
Total:          = 5 pods
```

### **Imágenes Utilizadas:**

**Imágenes Públicas:**
- `ghcr.io/mlflow/mlflow:v2.10.0`
- `evidently/evidently-service:latest`

**Imágenes Custom (construidas localmente):**
- `iris-api:latest` 
  - Base: `python:3.9-slim`
  - Includes: Modelo entrenado, FastAPI, scikit-learn
  - Build time training: `train.py`

- `workspace:latest`
  - Base: `python:3.9-slim`
  - Includes: JupyterLab + todas las libs MLOps

### **Uso de Recursos (Requests):**
```
CPU Total (requests):    1.1 cores
Memory Total (requests): ~2.5 GB
```

### **Uso de Recursos (Limits):**
```
CPU Total (limits):      3.5 cores
Memory Total (limits):   ~5.5 GB
```

**Nota:** Tu máquina necesita al menos **4GB RAM** disponibles para Docker.

---

## 🔄 Flujo de Datos

```
┌──────────────┐
│   Browser    │
│ (localhost)  │
└──────┬───────┘
       │ http://localhost:30003
       ▼
┌─────────────────────────────────────────┐
│         Kubernetes Cluster              │
│                                         │
│  ┌─────────────┐                       │
│  │  Workspace  │───┐                   │
│  │  (Jupyter)  │   │                   │
│  └─────────────┘   │                   │
│         │          │ DNS interno       │
│         │          │                   │
│         ├──────────┼─→ mlflow:5000     │
│         │          │                   │
│         ├──────────┼─→ evidently:8000  │
│         │          │                   │
│         └──────────┼─→ iris-api:8000   │
│                    │    ↓              │
│                    │  ┌─────┐ ┌─────┐ │
│                    └─→│Pod 1│ │Pod 2│ │
│                       │Iris │ │Iris │ │
│                       └─────┘ └─────┘ │
│                       Load Balanced    │
└─────────────────────────────────────────┘
```

---

## 💡 Conceptos Clave que se Aprenden

1. **Single Node Cluster:** Kubernetes puede correr en 1 nodo
2. **Pod Replication:** Iris API tiene 2 réplicas para HA
3. **Service Discovery:** DNS interno automático
4. **Network Isolation:** Pods se comunican por Services, no IPs directas
5. **Port Mapping:** NodePort permite acceso externo
6. **Immutable Infrastructure:** Todo es código (Terraform + Docker)
7. **Zero Config:** Students solo corren `./scripts/setup.sh`

---

## 📊 Comparación: Desarrollo vs Producción

| Aspecto | Clase 4 (Kind) | Producción (Cloud) |
|---------|----------------|-------------------|
| **Nodos** | 1 (control-plane) | 3+ (separados) |
| **Réplicas Iris** | 2 | 5-10+ (autoscaling) |
| **Services** | NodePort | LoadBalancer/Ingress |
| **Storage** | Ephemeral (en memoria) | Persistent Volumes |
| **Monitoring** | Manual (logs) | Prometheus + Grafana |
| **Secrets** | Variables env | Kubernetes Secrets |
| **Networking** | Default | Network Policies |

---

# 🚀 BONUS: Clúster Multi-Nodo con Kind

## ¿Por Qué Agregar Múltiples Nodos?

Si bien el clúster de 1 nodo es suficiente para aprendizaje, un clúster multi-nodo te permite experimentar con:

✅ **Distribución de Pods** entre múltiples nodos  
✅ **Node Affinity/Anti-Affinity** - Controlar dónde se despliegan los pods  
✅ **Tolerations & Taints** - Reservar nodos para workloads específicos  
✅ **Network Policies** - Aislamiento de red entre nodos  
✅ **Simulación más realista** de un clúster en la nube  

---

## 🎯 Arquitectura Multi-Nodo

### **Configuración: 1 Control Plane + 2 Workers**

```
┌────────────────────────────────────────────────┐
│              Kubernetes Cluster                │
│                                                │
│  ┌──────────────────────┐                     │
│  │   control-plane      │                     │
│  │   (API Server, etcd) │                     │
│  └──────────────────────┘                     │
│            │                                   │
│            ├───────────────┬──────────────┐   │
│            ▼               ▼              ▼   │
│     ┌───────────┐   ┌───────────┐  ┌────────┐│
│     │  worker-1 │   │  worker-2 │  │worker-3││
│     │           │   │           │  │        ││
│     │ • MLflow  │   │ • Iris-1  │  │• Iris-2││
│     │ • Evid.   │   │ • Works.  │  │        ││
│     └───────────┘   └───────────┘  └────────┘│
│                                                │
└────────────────────────────────────────────────┘
```

---

## 📝 Configuración Multi-Nodo

### **Paso 1: Crear `kind-config-multinodo.yaml`**

Crea un nuevo archivo de configuración:

```yaml
# infra/kind-config-multinodo.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: mlops-cluster-multinodo

# Definir múltiples nodos
nodes:
  # Control plane (master)
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
  
  # Worker node 1
  - role: worker
    labels:
      workload: monitoring  # Label para node affinity
    
  # Worker node 2
  - role: worker
    labels:
      workload: inference  # Label para separar workloads
    
  # Worker node 3 (opcional)
  - role: worker
    labels:
      workload: workspace
```

---

### **Paso 2: Crear el Clúster Multi-Nodo**

```bash
# Eliminar clúster actual si existe
kind delete cluster --name mlops-cluster

# Crear nuevo clúster multi-nodo
kind create cluster --config infra/kind-config-multinodo.yaml

# Verificar los nodos
kubectl get nodes

# Deberías ver:
# NAME                               STATUS   ROLE           AGE
# mlops-cluster-multinodo-control-plane   Ready    control-plane   1m
# mlops-cluster-multinodo-worker          Ready    <none>          1m
# mlops-cluster-multinodo-worker2         Ready    <none>          1m
# mlops-cluster-multinodo-worker3         Ready    <none>          1m
```

---

### **Paso 3: Modificar Deployments para Aprovechar Múltiples Nodos**

#### **Opción A: Node Affinity (Asignar pods a nodos específicos)**

Modifica `infra/iris_api.tf` para usar node affinity:

```hcl
# Agregar nodeSelector o affinity al deployment
resource "kubernetes_deployment" "iris_api" {
  # ... configuración existente ...
  
  spec {
    template {
      spec {
        # Node Selector - Simple
        node_selector = {
          workload = "inference"
        }
        
        # O usar Affinity - Más flexible
        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "workload"
                  operator = "In"
                  values   = ["inference"]
                }
              }
            }
          }
        }
        
        # Anti-affinity para distribuir pods en diferentes nodos
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
        
        container {
          # ... resto de la configuración ...
        }
      }
    }
  }
}
```

---

#### **Opción B: Dejar que Kubernetes Distribuya Automáticamente**

Si no especificas node selectors, Kubernetes distribuirá los pods automáticamente entre los workers basándose en recursos disponibles.

---

### **Paso 4: Desplegar y Verificar Distribución**

```bash
# Cargar imágenes en TODOS los nodos
kind load docker-image iris-api:latest --name mlops-cluster-multinodo
kind load docker-image workspace:latest --name mlops-cluster-multinodo

# Aplicar Terraform
cd infra
terraform init
terraform apply

# Ver en qué nodo corrió cada pod
kubectl get pods -o wide

# Output esperado:
# NAME                    READY   STATUS    NODE
# mlflow-xxx              1/1     Running   worker
# evidently-xxx           1/1     Running   worker
# iris-api-xxx-1          1/1     Running   worker2
# iris-api-xxx-2          1/1     Running   worker2
# workspace-xxx           1/1     Running   worker3
```

---

## 🔍 Comandos Útiles para Multi-Nodo

### **Ver distribución de pods:**
```bash
# Ver en qué nodo corre cada pod
kubectl get pods -o wide

# Ver pods por nodo
kubectl get pods --all-namespaces -o wide --sort-by=.spec.nodeName
```

### **Describir un nodo:**
```bash
kubectl describe node mlops-cluster-multinodo-worker

# Verás:
# - Pods corriendo en ese nodo
# - Recursos usados
# - Labels y taints
```

### **Drenar un nodo (simular fallo):**
```bash
# Mover todos los pods de un nodo
kubectl drain mlops-cluster-multinodo-worker2 --ignore-daemonsets

# Ver cómo Kubernetes redistribuye los pods
kubectl get pods -o wide -w

# Re-habilitar el nodo
kubectl uncordon mlops-cluster-multinodo-worker2
```

### **Aplicar taint a un nodo:**
```bash
# Evitar que se programen pods en el control-plane
kubectl taint nodes mlops-cluster-multinodo-control-plane key=value:NoSchedule

# Remover taint
kubectl taint nodes mlops-cluster-multinodo-control-plane key:NoSchedule-
```

---

## 📊 Recursos Necesarios

### **Clúster Single Node:**
- Docker: 4 GB RAM mínimo
- CPU: 2 cores
- Disk: 10 GB

### **Clúster Multi-Nodo (1 control + 3 workers):**
- Docker: **8-12 GB RAM** mínimo
- CPU: **4-6 cores**
- Disk: 20 GB
- Cada nodo consume ~2GB RAM base + pods

**Recomendación:** Solo usar multi-nodo si tu máquina tiene **16GB RAM** o más.

---

## 🎓 Ejercicios con Multi-Nodo

### **Ejercicio 1: Pod Anti-Affinity**
Configurar el Iris API para que cada réplica corra en un nodo diferente (alta disponibilidad real).

### **Ejercicio 2: Node Selector**
Asignar MLflow y Evidently al nodo de "monitoring", e Iris API a "inference".

### **Ejercicio 3: Simular Fallo de Nodo**
Drenar un worker y observar cómo Kubernetes redistribuye los pods automáticamente.

### **Ejercicio 4: Escalar Horizontalmente**
Escalar Iris API a 4 réplicas y ver cómo se distribuyen entre los workers.

---

## ⚠️ Consideraciones Importantes

### **Ventajas del Multi-Nodo:**
✅ Simulación más realista de producción  
✅ Experimentar con node affinity/anti-affinity  
✅ Probar resiliencia ante fallos de nodo  
✅ Mejor distribución de carga  

### **Desventajas:**
❌ Mayor consumo de recursos locales  
❌ Más complejo de debuggear  
❌ Más lento para crear/destruir  
❌ Puede saturar máquinas con poca RAM  

### **¿Cuándo Usar Multi-Nodo?**
- ✅ Demostrar conceptos avanzados de scheduling
- ✅ Testing de resiliencia
- ✅ Preparación para despliegue real en cloud
- ❌ NO recomendado para laptops con < 8GB RAM

---

## 🎯 Resumen

**En esta clase desplegamos una arquitectura MLOps completa en Kubernetes con:**

- ✅ **1 nodo** por defecto (single-node, ideal para aprendizaje)
- ✅ **5 pods** distribuidos (1 MLflow, 1 Evidently, 2 Iris API, 1 Workspace)
- ✅ **4 servicios** expuestos con NodePort
- ✅ **Alta disponibilidad** en el API de inferencia (2 réplicas)
- ✅ **DNS interno** para comunicación entre servicios
- ✅ **Zero instalación local** para los estudiantes
- ✅ **Todo como código** (Terraform + Docker)
- ✅ **BONUS:** Opción de expandir a multi-nodo para experimentación avanzada

**Todo gestionado con 2 comandos:**
```bash
./scripts/setup.sh    # Levanta todo
./scripts/cleanup.sh  # Destruye todo
```

---

## 📚 Recursos Adicionales

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kind Multi-Node Clusters](https://kind.sigs.k8s.io/docs/user/configuration/#nodes)
- [Kubernetes Scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)

---

**Creado para Clase 4 - MLOps en Kubernetes** 🚀

