# 🏗️ Arquitectura de la Clase 4

## 📐 Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         TU LAPTOP                                    │
│                                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Browser    │  │  Browser    │  │  Browser    │  │   curl      │  │
│  │  :30001     │  │  :30002     │  │  :30003     │  │  :30004     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │
│         │                │                │                │          │
└─────────┼────────────────┼────────────────┼────────────────┼──────────┘
          │                │                │                │
          │ NodePort       │ NodePort       │ NodePort       │ NodePort
          │ 30001          │ 30002          │ 30003          │ 30004
          │                │                │                │
┌─────────┼────────────────┼────────────────┼────────────────┼──────────┐
│         │                │                │                │          │
│    ┌────▼────────────────▼────────────────▼────────────────▼────┐    │
│    │              KIND CLUSTER (mlops-cluster)                   │    │
│    │                  (Docker Container)                          │    │
│    │                                                              │    │
│    │  ┌──────────────────────────────────────────────────────┐  │    │
│    │  │              Kubernetes Control Plane                 │  │    │
│    │  └──────────────────────────────────────────────────────┘  │    │
│    │                                                              │    │
│    │  ┌──────────────────────────────────────────────────────┐  │    │
│    │  │                  DEPLOYMENTS                          │  │    │
│    │  │                                                        │  │    │
│    │  │  ┌────────────────┐  ┌────────────────┐             │  │    │
│    │  │  │  MLflow Pod    │  │ Evidently Pod  │             │  │    │
│    │  │  │  :5000         │  │  :8000         │             │  │    │
│    │  │  └────────────────┘  └────────────────┘             │  │    │
│    │  │                                                        │  │    │
│    │  │  ┌────────────────┐  ┌────────────────┐             │  │    │
│    │  │  │  Iris API      │  │  Iris API      │  (2 replicas)│  │    │
│    │  │  │  Pod 1         │  │  Pod 2         │             │  │    │
│    │  │  │  :8000         │  │  :8000         │             │  │    │
│    │  │  └────────────────┘  └────────────────┘             │  │    │
│    │  │                                                        │  │    │
│    │  │  ┌────────────────┐                                  │  │    │
│    │  │  │ Workspace Pod  │                                  │  │    │
│    │  │  │ (JupyterLab)   │                                  │  │    │
│    │  │  │  :8888         │                                  │  │    │
│    │  │  └────────────────┘                                  │  │    │
│    │  │                                                        │  │    │
│    │  └──────────────────────────────────────────────────────┘  │    │
│    │                                                              │    │
│    │  ┌──────────────────────────────────────────────────────┐  │    │
│    │  │                  SERVICES                             │  │    │
│    │  │                                                        │  │    │
│    │  │  mlflow-service        ───▶  MLflow Pod              │  │    │
│    │  │  evidently-service     ───▶  Evidently Pod           │  │    │
│    │  │  iris-service          ───▶  Iris API Pods (LB)      │  │    │
│    │  │  workspace-service     ───▶  Workspace Pod           │  │    │
│    │  │                                                        │  │    │
│    │  └──────────────────────────────────────────────────────┘  │    │
│    │                                                              │    │
│    │  ┌──────────────────────────────────────────────────────┐  │    │
│    │  │              DNS INTERNO (CoreDNS)                    │  │    │
│    │  │                                                        │  │    │
│    │  │  mlflow-service.default.svc.cluster.local:5000       │  │    │
│    │  │  evidently-service.default.svc.cluster.local:8000    │  │    │
│    │  │  iris-service.default.svc.cluster.local:8000         │  │    │
│    │  │                                                        │  │    │
│    │  └──────────────────────────────────────────────────────┘  │    │
│    │                                                              │    │
│    └──────────────────────────────────────────────────────────────┘    │
│                                                                           │
│                         DOCKER DAEMON                                    │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Comunicación

### 1. Desde tu Laptop a los Servicios

```
Browser (http://localhost:30001)
    │
    ├─▶ Docker Port Mapping (30001 → 30001)
    │
    └─▶ Kind Node (30001 → NodePort)
        │
        └─▶ Kubernetes Service (mlflow-service)
            │
            └─▶ MLflow Pod (:5000)
```

### 2. Comunicación Interna (DNS de Kubernetes)

```
Workspace Pod (JupyterLab)
    │
    ├─▶ requests.get("http://mlflow-service:5000")
    │   │
    │   └─▶ Kubernetes DNS resuelve a ClusterIP
    │       │
    │       └─▶ MLflow Pod
    │
    ├─▶ requests.post("http://iris-service:8000/predict")
    │   │
    │   └─▶ Kubernetes Service (Load Balancer interno)
    │       │
    │       ├─▶ Iris API Pod 1  (50% tráfico)
    │       └─▶ Iris API Pod 2  (50% tráfico)
    │
    └─▶ requests.get("http://evidently-service:8000")
        │
        └─▶ Evidently Pod
```

---

## 🎭 Componentes por Capa

### Capa 1: Host (Tu Laptop)

| Componente | Función |
|------------|---------|
| Docker Desktop | Runtime de contenedores |
| Kind CLI | Gestión del clúster |
| kubectl | CLI de Kubernetes |
| Terraform | Gestión de infraestructura |
| Browser | Acceso a UIs web |

### Capa 2: Kind Cluster (Contenedor Docker)

| Componente | Función |
|------------|---------|
| Control Plane | API Server, Scheduler, Controller Manager |
| kubelet | Agente en el nodo |
| CoreDNS | Resolución DNS interna |
| kube-proxy | Networking y load balancing |

### Capa 3: Aplicaciones (Pods)

| Pod | Imagen | Puerto | Réplicas | Tipo |
|-----|--------|--------|----------|------|
| **MLflow** | ghcr.io/mlflow/mlflow:v2.10.0 | 5000 | 1 | Stateful |
| **Evidently** | evidently/evidently-service:latest | 8000 | 1 | Stateful |
| **Iris API** | iris-api:latest (local) | 8000 | 2 | Stateless |
| **Workspace** | workspace:latest (local) | 8888 | 1 | Stateful |

### Capa 4: Servicios (Networking)

| Service | Tipo | Puerto Interno | Puerto Externo | Función |
|---------|------|----------------|----------------|---------|
| **mlflow-service** | NodePort | 5000 | 30001 | Tracking UI |
| **evidently-service** | NodePort | 8000 | 30002 | Monitoring UI |
| **iris-service** | NodePort | 8000 | 30004 | Predicción API |
| **workspace-service** | NodePort | 8888 | 30003 | Jupyter UI |

---

## 🔐 Patrón de Seguridad

### Red Interna (ClusterIP)

```
┌─────────────────────────────────────────┐
│     COMUNICACIÓN INTERNA SEGURA         │
│                                         │
│  Workspace ───▶ iris-service:8000      │
│           └───▶ mlflow-service:5000    │
│           └───▶ evidently-service:8000 │
│                                         │
│  ✅ Solo accesible dentro del clúster   │
│  ✅ DNS automático                       │
│  ✅ Load balancing automático            │
└─────────────────────────────────────────┘
```

### Exposición Externa (NodePort)

```
┌─────────────────────────────────────────┐
│      ACCESO DESDE EL NAVEGADOR          │
│                                         │
│  localhost:30001 ───▶ MLflow UI        │
│  localhost:30002 ───▶ Evidently UI     │
│  localhost:30003 ───▶ Jupyter UI       │
│  localhost:30004 ───▶ Iris API         │
│                                         │
│  ⚠️  Solo para desarrollo local         │
│  ⚠️  En prod usar Ingress + TLS         │
└─────────────────────────────────────────┘
```

---

## 💾 Persistencia de Datos

### ❌ Sin Persistencia (Ephemeral)

```
Pod (MLflow)
  │
  └─▶ EmptyDir Volume
      │
      └─▶ Se pierde al eliminar el pod
```

**Consecuencia:** Los experimentos de MLflow se pierden al reiniciar el pod.

### ✅ Con Persistencia (PersistentVolumeClaim)

```
Pod (MLflow)
  │
  └─▶ PersistentVolumeClaim
      │
      └─▶ PersistentVolume (hostPath en Kind)
          │
          └─▶ Directorio en el nodo
              │
              └─▶ Sobrevive reinicios
```

**Nota:** En esta práctica usamos volúmenes efímeros para simplicidad.  
Para producción, se deben usar PVCs.

---

## 🔄 Load Balancing

### Iris API (2 Réplicas)

```
Petición al Service (iris-service:8000)
    │
    ├─▶ kube-proxy intercepta
    │
    └─▶ Round-robin entre pods
        │
        ├─▶ iris-api-xxxxx-pod1  (50%)
        └─▶ iris-api-xxxxx-pod2  (50%)
```

**Ventajas:**
- Alta disponibilidad
- Tolerancia a fallos
- Mayor throughput

---

## 🚀 Escalamiento

### Horizontal (Réplicas)

```bash
# Aumentar réplicas
kubectl scale deployment iris-api --replicas=5

# Resultado:
iris-api-xxxxx-pod1  ─┐
iris-api-xxxxx-pod2   │
iris-api-xxxxx-pod3   ├─▶ Tráfico distribuido
iris-api-xxxxx-pod4   │
iris-api-xxxxx-pod5  ─┘
```

### Vertical (Recursos)

```yaml
resources:
  requests:
    cpu: "250m"      # Mínimo garantizado
    memory: "512Mi"
  limits:
    cpu: "500m"      # Máximo permitido
    memory: "1Gi"
```

---

## 🔍 Health Checks

### Liveness Probe (¿Está vivo?)

```yaml
liveness_probe {
  http_get {
    path = "/health"
    port = 8000
  }
  initial_delay_seconds = 10
  period_seconds        = 10
}
```

Si falla → Kubernetes reinicia el pod

### Readiness Probe (¿Está listo?)

```yaml
readiness_probe {
  http_get {
    path = "/health"
    port = 8000
  }
  initial_delay_seconds = 5
  period_seconds        = 5
}
```

Si falla → Kubernetes lo saca del balanceo

---

## 🎯 Diferencias: Docker Compose vs Kubernetes

| Aspecto | Docker Compose | Kubernetes (Kind) |
|---------|----------------|-------------------|
| **Orquestación** | Básica (un host) | Avanzada (multi-nodo) |
| **Networking** | Bridge simple | DNS interno + Services |
| **Load Balancing** | Manual (nginx) | Automático (kube-proxy) |
| **Escalamiento** | Manual | Declarativo (replicas) |
| **Health Checks** | Básicos | Liveness + Readiness |
| **Storage** | Volúmenes Docker | PVCs + StorageClasses |
| **Configuración** | docker-compose.yml | Manifests YAML / Terraform |
| **Producción** | ❌ No recomendado | ✅ Estándar de industria |

---

## 📊 Gestión de Configuración

### ConfigMaps (Configuración)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: evidently-config
data:
  config.yaml: |
    service:
      port: 8000
    workspace:
      path: /app/workspace
```

Montado en el pod como archivo.

### Environment Variables

```yaml
env:
  - name: MLFLOW_TRACKING_URI
    value: "http://mlflow-service:5000"
```

Inyectadas en el runtime del contenedor.

---

## 🏗️ Infrastructure as Code (Terraform)

```
Terraform (HCL)
    │
    ├─▶ provider.tf     (Configuración de providers)
    ├─▶ cluster.tf      (Clúster Kind)
    ├─▶ mlflow.tf       (Deployment + Service MLflow)
    ├─▶ evidently.tf    (Deployment + Service Evidently)
    ├─▶ iris_api.tf     (Deployment + Service Iris)
    ├─▶ workspace.tf    (Deployment + Service Workspace)
    ├─▶ variables.tf    (Parámetros configurables)
    └─▶ outputs.tf      (Información de salida)
        │
        └─▶ terraform apply
            │
            └─▶ Kubernetes API
                │
                └─▶ Recursos creados
```

**Ventajas:**
- ✅ Versionable en Git
- ✅ Reproducible
- ✅ Auditable
- ✅ Fácil de destruir y recrear

---

## 🎓 Conceptos Clave

### 1. Patrón Inmutable

```
Dockerfile
    │
    └─▶ RUN python train.py  (Build time)
        │
        └─▶ model.joblib queda en la imagen
            │
            └─▶ Al hacer deploy, el modelo ya está presente
```

### 2. DNS de Kubernetes

```
<service-name>.<namespace>.svc.cluster.local

Ejemplo:
mlflow-service.default.svc.cluster.local:5000

Simplificado (mismo namespace):
mlflow-service:5000
```

### 3. Labels y Selectors

```yaml
# Deployment
labels:
  app: iris-api

# Service
selector:
  app: iris-api  # ← Conecta con los pods que tengan este label
```

---

## 🔮 Próximos Pasos (Clases Futuras)

1. **Ingress Controller** - Un único punto de entrada
2. **Cert Manager** - TLS automático
3. **Horizontal Pod Autoscaler** - Escalado automático
4. **Prometheus + Grafana** - Monitoring avanzado
5. **ArgoCD** - GitOps para CI/CD
6. **Helm Charts** - Empaquetado de aplicaciones
7. **Migración a la nube** - EKS, GKE, AKS

---

¡Esta arquitectura es la base de MLOps en producción! 🚀

