# 🏗️ Arquitectura AWS EKS para MLOps

## 📊 Diagrama General de la Solución

```
Internet
   ↓
DNS Public (Route53 opcional)
   ↓
┌─────────────────────────────────────────────────────────┐
│            AWS Account (us-east-1)                      │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │           VPC (10.0.0.0/16)                        │ │
│  │                                                    │ │
│  │  ┌─────────────────────┐                          │ │
│  │  │ Internet Gateway    │                          │ │
│  │  └──────────┬──────────┘                          │ │
│  │             │                                      │ │
│  │  ┌──────────┴──────────┐                          │ │
│  │  │                     │                          │ │
│  │  ▼                     ▼                          │ │
│  │  ┌──────────────────┐ ┌──────────────────┐       │ │
│  │  │ Public Subnet    │ │ Public Subnet    │       │ │
│  │  │ (10.0.1.0/24)    │ │ (10.0.2.0/24)    │       │ │
│  │  │ AZ: us-east-1a   │ │ AZ: us-east-1b   │       │ │
│  │  │                  │ │                  │       │ │
│  │  │ ┌──────────────┐ │ │ ┌──────────────┐ │       │ │
│  │  │ │ NAT Gateway  │ │ │ │ NAT Gateway  │ │       │ │
│  │  │ └──────────────┘ │ │ └──────────────┘ │       │ │
│  │  │                  │ │                  │       │ │
│  │  │ ┌──────────────┐ │ │ ┌──────────────┐ │       │ │
│  │  │ │  ELB (ALB)   │ │ │ │  ELB (NLB)   │ │       │ │
│  │  │ │ (Services)   │ │ │ │ (Services)   │ │       │ │
│  │  │ └──────────────┘ │ │ └──────────────┘ │       │ │
│  │  └──────────────────┘ └──────────────────┘       │ │
│  │             ▲                   ▲                │ │
│  │             │                   │                │ │
│  │  ┌──────────┴───────────────────┴──────────┐    │ │
│  │  │                                         │    │ │
│  │  ▼                                         ▼    │ │
│  │  ┌──────────────────┐        ┌──────────────────┐│ │
│  │  │ Private Subnet   │        │ Private Subnet   ││ │
│  │  │ (10.0.10.0/24)   │        │ (10.0.11.0/24)   ││ │
│  │  │ AZ: us-east-1a   │        │ AZ: us-east-1b   ││ │
│  │  │                  │        │                  ││ │
│  │  │ ┌────────────┐   │        │ ┌────────────┐   ││ │
│  │  │ │EC2: Node 1 │   │        │ │EC2: Node 2 │   ││ │
│  │  │ │(t3.medium) │   │        │ │(t3.medium) │   ││ │
│  │  │ │            │   │        │ │            │   ││ │
│  │  │ │ ┌────────┐ │   │        │ │ ┌────────┐ │   ││ │
│  │  │ │ │ MLflow │ │   │        │ │ │ Iris-1 │ │   ││ │
│  │  │ │ │  Pod   │ │   │        │ │ │  Pod   │ │   ││ │
│  │  │ │ └────────┘ │   │        │ │ └────────┘ │   ││ │
│  │  │ │ ┌────────┐ │   │        │ │ ┌────────┐ │   ││ │
│  │  │ │ │Evidntly│ │   │        │ │ │ Iris-2 │ │   ││ │
│  │  │ │ │  Pod   │ │   │        │ │ │  Pod   │ │   ││ │
│  │  │ │ └────────┘ │   │        │ │ └────────┘ │   ││ │
│  │  │ │ ┌────────┐ │   │        │ └────────────┘   ││ │
│  │  │ │ │Jupyter │ │   │                           ││ │
│  │  │ │ │  Pod   │ │   │                           ││ │
│  │  │ │ └────────┘ │   │                           ││ │
│  │  │ └────────────┘   │                           ││ │
│  │  └──────────────────┘ ──────────────────────────┘│ │
│  │                                                    │ │
│  │  ┌────────────────────────────────────────────┐  │ │
│  │  │    EKS Control Plane (Managed by AWS)      │  │ │
│  │  │    - API Server                            │  │ │
│  │  │    - etcd database                         │  │ │
│  │  │    - Scheduler                             │  │ │
│  │  │    - Controller Manager                    │  │ │
│  │  └────────────────────────────────────────────┘  │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │         ECR (Elastic Container Registry)           │ │
│  │  - iris-api:latest (tu imagen)                    │ │
│  │  - workspace:latest (tu imagen)                   │ │
│  │  - Referencia a: ghcr.io/mlflow/mlflow            │ │
│  │  - Referencia a: evidently/evidently-service      │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │            Storage & Persistence                   │ │
│  │  - EBS Volumes (para datos de MLflow/Evidently)   │ │
│  │  - RDS (opcional - para bases de datos)           │ │
│  │  - S3 (opcional - para artifacts)                 │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │         IAM Roles & Security                       │ │
│  │  - EKS Node IAM Role (permisos de nodos)         │ │
│  │  - IRSA (IAM Roles for Service Accounts)         │ │
│  │  - Security Groups (firewall)                     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Monitoring & Logging                       │ │
│  │  - CloudWatch Logs (logs de pods)                │ │
│  │  - CloudWatch Metrics (métricas)                 │ │
│  │  - X-Ray (tracing)                                │ │
│  │  - AWS Container Insights                         │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔌 Networking y Seguridad

### VPC Structure

```
VPC: 10.0.0.0/16
│
├─ Public Subnets (accesibles desde internet)
│  ├─ 10.0.1.0/24 (us-east-1a)
│  │  └─ NAT Gateway (EIP)
│  │  └─ Load Balancers
│  └─ 10.0.2.0/24 (us-east-1b)
│     └─ NAT Gateway (EIP)
│     └─ Load Balancers
│
└─ Private Subnets (nodos EKS)
   ├─ 10.0.10.0/24 (us-east-1a)
   │  └─ EC2 Nodes (Worker Node 1)
   │  └─ Pods (comunicación interna)
   └─ 10.0.11.0/24 (us-east-1b)
      └─ EC2 Nodes (Worker Node 2)
      └─ Pods (comunicación interna)
```

### Security Groups

```
1. EKS Control Plane Security Group
   ├─ Inbound:
   │  └─ Port 443 from Nodes SG (API communication)
   └─ Outbound:
      └─ All (para downloads de imágenes)

2. Nodes Security Group
   ├─ Inbound:
   │  ├─ Ports 30000-32767 from ALB/NLB (NodePort access)
   │  ├─ Port 443 from Control Plane SG
   │  ├─ Port 10250 (kubelet) entre nodos
   │  └─ Toda comunicación entre nodos
   └─ Outbound:
      └─ All (para downloads de imágenes)

3. Load Balancer Security Group
   ├─ Inbound:
   │  ├─ Port 5000 from 0.0.0.0/0 (MLflow)
   │  ├─ Port 8000 from 0.0.0.0/0 (Iris API / Evidently)
   │  └─ Port 8888 from 0.0.0.0/0 (Jupyter)
   └─ Outbound:
      └─ All to Nodes SG (forwarding)
```

### Service Architecture

```
┌─────────────────────────────────────────────────┐
│         Internet Traffic (HTTPS/HTTP)           │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   AWS Load Balancer   │
         │   (ALB or NLB)        │
         │  - Public IP          │
         │  - DNS name           │
         └───────────┬───────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐
   │Service: │ │Service: │ │Service: │
   │MLflow   │ │Iris API │ │Workspace│
   │(Type:   │ │(Type:   │ │(Type:   │
   │LB)      │ │LB)      │ │LB)      │
   └─────────┘ └─────────┘ └─────────┘
        │            │            │
   ┌────┴───┬────────┼───┬────────┴──┐
   ▼        ▼        ▼   ▼           ▼
 Pod1     Pod1    Pod1 Pod2        Pod1
mlflow   evid.   iris  iris      jupytr
```

---

## 📦 Componentes Desplegados

### 1. MLflow Service
```
Deployment: mlflow
├─ Replicas: 1
├─ Image: ghcr.io/mlflow/mlflow:v2.10.0
├─ Service Type: LoadBalancer
├─ Port: 5000
├─ Storage: EBS Volume 50GB
├─ CPU: 250m (request) / 500m (limit)
└─ Memory: 512Mi (request) / 1Gi (limit)

Access:
  External: http://mlflow-<random>.us-east-1.elb.amazonaws.com:5000
  Internal: http://mlflow-service.default.svc.cluster.local:5000
```

### 2. Evidently Service
```
Deployment: evidently
├─ Replicas: 1
├─ Image: evidently/evidently-service:latest
├─ Service Type: LoadBalancer
├─ Port: 8000
├─ Storage: EBS Volume 20GB
├─ CPU: 250m (request) / 500m (limit)
└─ Memory: 512Mi (request) / 1Gi (limit)

Access:
  External: http://evidently-<random>.us-east-1.elb.amazonaws.com:8000
  Internal: http://evidently-service.default.svc.cluster.local:8000
```

### 3. Iris API Service
```
Deployment: iris-api
├─ Replicas: 2 (High Availability)
├─ Image: <ECR>/iris-api:latest
├─ Service Type: LoadBalancer
├─ Port: 8000
├─ CPU: 100m (request) / 500m (limit)
└─ Memory: 256Mi (request) / 512Mi (limit)

Load Balancing:
  - Round-robin entre 2 pods
  - Auto health checks
  - Auto failover

Access:
  External: http://iris-api-<random>.us-east-1.elb.amazonaws.com:8000
  Internal: http://iris-service.default.svc.cluster.local:8000
```

### 4. Workspace (Jupyter) Service
```
Deployment: workspace
├─ Replicas: 1
├─ Image: <ECR>/workspace:latest
├─ Service Type: LoadBalancer
├─ Port: 8888
├─ CPU: 250m (request) / 1000m (limit)
└─ Memory: 512Mi (request) / 2Gi (limit)

Environment Variables:
├─ MLFLOW_TRACKING_URI=http://mlflow-service:5000
├─ EVIDENTLY_SERVICE_URL=http://evidently-service:8000
├─ IRIS_API_URI=http://iris-service:8000
└─ IRIS_API_URL=http://iris-service:8000

Access:
  External: http://workspace-<random>.us-east-1.elb.amazonaws.com:8888
  Internal: http://workspace-service.default.svc.cluster.local:8888
```

---

## 💾 Almacenamiento (Storage)

### EBS Volumes

```
┌──────────────────────────────────────────────┐
│         Availability Zone: us-east-1a        │
├──────────────────────────────────────────────┤
│                                              │
│  EBS Volume: mlflow-data-1                  │
│  ├─ Size: 50 GB                            │
│  ├─ Type: gp3 (General Purpose)            │
│  ├─ Mounted at: /mlflow/data               │
│  └─ Pod: mlflow                            │
│                                              │
│  EBS Volume: evidently-data-1               │
│  ├─ Size: 20 GB                            │
│  ├─ Type: gp3                              │
│  ├─ Mounted at: /workspace                │
│  └─ Pod: evidently                         │
│                                              │
└──────────────────────────────────────────────┘
```

### Storage Classes (Kubernetes)

```yaml
# Fast storage
StorageClass: gp3-fast
├─ IOPS: 3000
├─ Throughput: 125 MB/s
└─ Use case: Databases, high-performance

# Standard storage
StorageClass: gp3-standard
├─ IOPS: 3000
├─ Throughput: 125 MB/s
└─ Use case: General purpose (default)

# Cost-optimized
StorageClass: sc1
├─ IOPS: Low
├─ Throughput: Limited
└─ Use case: Infrequent access
```

---

## 🔐 IAM Architecture

### Node Role Permissions

```
EKS Node IAM Role
├─ AmazonEKSWorkerNodePolicy
│  └─ Permisos básicos para nodos
├─ AmazonEKS_CNI_Policy
│  └─ Permisos de networking
├─ AmazonEC2ContainerRegistryReadOnly
│  └─ Pull de ECR (tus imágenes privadas)
└─ CloudWatchLogsAgentServerPolicy
   └─ Escribir logs a CloudWatch
```

### Service Account Roles (IRSA)

```
Kubernetes Service Account
├─ mlflow-sa
│  └─ IAM Role: mlflow-role
│     └─ Permisos: S3, RDS (si usas)
│
├─ iris-api-sa
│  └─ IAM Role: iris-api-role
│     └─ Permisos: CloudWatch metrics
│
├─ evidently-sa
│  └─ IAM Role: evidently-role
│     └─ Permisos: S3 artifacts
│
└─ workspace-sa
   └─ IAM Role: workspace-role
      └─ Permisos: MLflow, Evidently APIs
```

---

## 📊 Datos: Flujo Completo

```
1. Usuario abre Jupyter Lab (workspace)
   │
   ▼
2. Ejecuta notebook con código de entrenamiento
   │
   ├─ Conecta a MLflow en http://mlflow-service:5000
   │
   ├─ Entrena modelo
   │
   ├─ Registra métricas en MLflow
   │  └─ Almacenado en EBS Volume (mlflow-data)
   │
   └─ Registra datos en Evidently
      └─ Almacenado en EBS Volume (evidently-data)

3. Predicción: Usuario llama al Iris API
   │
   ├─ LoadBalancer distribuye a 2 pods
   │
   ├─ Pod 1 o Pod 2 procesa predicción
   │
   └─ Respuesta en JSON

4. Análisis de Drift: Usuario accede a Evidently
   │
   ├─ Compara datos nuevos con históricos
   │
   ├─ Detecta cambios
   │
   └─ Genera reportes HTML
```

---

## 🚀 Scaling & Auto-scaling

### Horizontal Pod Autoscaling (HPA)

```
Monitor: CPU Utilization
Target: 70%

If CPU > 70%:
  Iris API replicas: 2 → 3 → 4 → 10 (max)

If CPU < 30%:
  Iris API replicas: 4 → 3 → 2 (min)

Decision every 30 seconds
```

### Cluster Autoscaling

```
Monitor: Pod scheduling failures

If pod can't be scheduled:
  Nodes: 2 → 3 (add new node)
  Type: t3.medium (same type)

If node underutilized (< 50%):
  Remove node (after cooldown)
```

---

## 🔄 High Availability

### Availability Zones

```
AWS Region: us-east-1 (3 AZs)
│
├─ us-east-1a
│  ├─ Public Subnet: 10.0.1.0/24
│  ├─ Private Subnet: 10.0.10.0/24
│  └─ EC2 Node 1 (Worker)
│
└─ us-east-1b
   ├─ Public Subnet: 10.0.2.0/24
   ├─ Private Subnet: 10.0.11.0/24
   └─ EC2 Node 2 (Worker)

Protección contra fallos:
✅ Si AZ-a falla → AZ-b continúa
✅ Si nodo 1 falla → Nodo 2 continúa
✅ Si pod falla → Kubernetes reschedule automático
```

---

## 💰 Costos: Desglose

```
Resource                   Qty   Monthly Cost
─────────────────────────────────────────────
EKS Control Plane          1     $73.00
EC2 t3.medium             2     $60.00
Load Balancer             3     $20.00
EBS gp3 70GB              ~     $5.00
Data Transfer Out         ~     $5.00
─────────────────────────────────────────────
TOTAL ESTIMATE:                 ~$160.00/mes

Cost Optimization Options:
- Spot instances (up to 50% discount)
- Reserved instances (up to 40% discount)
- Downscale or destroy when not in use ($0)
```

---

## 📈 Escalado Manual

```bash
# Scale Iris API to 5 replicas
kubectl scale deployment iris-api --replicas=5

# Scale nodes (via Terraform)
terraform apply -var="desired_capacity=4"

# Scale down (save costs)
kubectl scale deployment iris-api --replicas=1
terraform apply -var="desired_capacity=1"
```

---

## ✅ Health Checks

```
Liveness Probe: Is the pod alive?
├─ Endpoint: /health
├─ Interval: 10s
├─ Timeout: 5s
└─ Action if fails: Restart pod

Readiness Probe: Is the pod ready for traffic?
├─ Endpoint: /ready
├─ Interval: 5s
├─ Timeout: 3s
└─ Action if fails: Remove from LoadBalancer
```

---

**Diagrama actualizado: Clase 5 - MLOps en AWS EKS** 🚀


