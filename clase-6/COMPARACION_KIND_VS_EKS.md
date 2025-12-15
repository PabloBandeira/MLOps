# 📊 KIND vs AWS EKS: Comparación Completa

## 📋 Tabla Comparativa

| Aspecto | KIND | AWS EKS |
|---------|------|---------|
| **Ubicación** | Local (tu máquina) | Cloud (AWS) |
| **Infraestructura** | Docker en tu PC | AWS managed |
| **Costo Mensual** | $0 | ~$160 (aprox) |
| **Setup Time** | 2-5 minutos | 15-20 minutos |
| **Escalabilidad** | Limitada a tu PC | Prácticamente ilimitada |
| **Nodos** | 1-3 (local) | 2+ (recomendado) |
| **Storage** | Efímero | Persistent (EBS) |
| **Networking** | localhost:30xxx | DNS público + LoadBalancer |
| **Acceso** | localhost | Internet global |
| **Usar para** | Desarrollo local | Producción, demostración |

---

## 🔍 Diferencias Técnicas Clave

### 1. Provisión de Infraestructura

**KIND:**
```
Tu máquina (Docker Desktop)
└── Docker daemon
    └── Contenedor Docker (KIND node)
        └── Kubernetes cluster
            └── Tus pods
```

**EKS:**
```
AWS Account
├── VPC (Virtual Private Cloud)
│   ├── Subnets públicas
│   │   └── Load Balancer
│   └── Subnets privadas
│       └── Nodos EC2 (worker nodes)
│           └── Kubernetes cluster
│               └── Tus pods
└── Control plane (gestionado por AWS)
```

### 2. Acceso a Servicios

**KIND:**
```
localhost:30001 → NodePort → Service → Pod
```

**EKS:**
```
Load Balancer DNS → LoadBalancer Service → ClusterIP → Pod
```

### 3. Networking

**KIND:**
```yaml
# NodePort (puerto fijo en el nodo)
apiVersion: v1
kind: Service
metadata:
  name: mlflow-service
spec:
  type: NodePort
  ports:
  - port: 5000
    nodePort: 30001  # ← Puerto en localhost
```

**EKS:**
```yaml
# LoadBalancer (DNS dinámico)
apiVersion: v1
kind: Service
metadata:
  name: mlflow-service
spec:
  type: LoadBalancer
  ports:
  - port: 5000
    targetPort: 5000
# AWS crea automáticamente:
# - Network Load Balancer
# - DNS: mlflow-service-abc123.us-east-1.elb.amazonaws.com
```

### 4. Imágenes Docker

**KIND:**
```bash
# Build local
docker build -t iris-api:latest .

# Load en KIND
kind load docker-image iris-api:latest --name mlops-cluster

# Terraform usa:
image = "iris-api:latest"
```

**EKS:**
```bash
# Build local
docker build -t iris-api:latest .

# Push a ECR (registry privado)
docker tag iris-api:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/iris-api:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/iris-api:latest

# Terraform usa:
image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/iris-api:latest"
```

### 5. Almacenamiento

**KIND:**
```yaml
# Sin persistent volumes
# Los datos se pierden al reiniciar pod
volumeMounts:
- name: tmpfs
  mountPath: /data
volumes:
- name: tmpfs
  emptyDir: {}
```

**EKS:**
```yaml
# Con EBS volumes
volumeMounts:
- name: mlflow-data
  mountPath: /mlflow/data
volumes:
- name: mlflow-data
  awsElasticBlockStore:
    volumeID: vol-abc123xyz
    fsType: ext4
```

### 6. Debugging y Logs

**KIND:**
```bash
# Ver logs locales
kubectl logs pod/iris-api-xyz123

# Port forward local
kubectl port-forward pod/iris-api-xyz123 8000:8000

# Acceder via localhost
curl localhost:8000/health
```

**EKS:**
```bash
# Ver logs en CloudWatch
kubectl logs pod/iris-api-xyz123
# Archivo: /aws/eks/mlops-cluster-prod/cluster

# Port forward (remoto)
kubectl port-forward pod/iris-api-xyz123 8000:8000

# O usar LoadBalancer
curl http://mlflow-service-abc123.us-east-1.elb.amazonaws.com:5000
```

---

## 🚀 Casos de Uso

### Usa KIND cuando:
- ✅ Estás desarrollando localmente
- ✅ Quieres experimentar sin costos
- ✅ Necesitas setup rápido
- ✅ Trabajas offline
- ✅ Tienes recursos limitados
- ✅ Estás aprendiendo Kubernetes

### Usa EKS cuando:
- ✅ Necesitas producción
- ✅ Requieres alta disponibilidad
- ✅ Escalas horizontalmente
- ✅ Necesitas acceso desde internet
- ✅ Requieres soporte enterprise
- ✅ Necesitas compliance (SOC2, HIPAA, etc)
- ✅ Trabajas en equipo

---

## 💰 Comparación de Costos

### KIND (Local)
```
Componente                    Costo Mensual
─────────────────────────────────────────
Docker Desktop (gratis)       $0
RAM local (asumimos ya existe) $0
Almacenamiento local         $0
─────────────────────────────────────────
Total:                        $0
```

### EKS (AWS)
```
Componente                    Costo Mensual
─────────────────────────────────────────
EKS Control Plane            $73.00
EC2 t3.medium × 2            $60.00 (2x $30)
Load Balancer (ALB/NLB)      $20.00
EBS Storage (30GB)           $5.00
Data Transfer (egress)       ~$5.00
─────────────────────────────────────────
Total:                        ~$160.00

Opciones para reducir costos:
- Usar t3.micro/small        → $30-50/mes
- Usar spot instances        → -50% en EC2
- Usar free tier (1 año)     → $0 iniciales
- Destruir cuando no usas    → $0 (importante!)
```

---

## 📈 Escalabilidad

### KIND: Limitaciones

```
Factores limitantes:
- RAM de tu máquina          (típicamente 4-16 GB)
- CPU disponible             (típicamente 2-8 cores)
- Almacenamiento local       (típicamente 256 GB)
- Conexión de internet       (solo para pull de imágenes)

Máximo realista:
- 1-3 nodos
- 10-20 pods
- CPU total: 4-8 cores
- RAM total: 4-16 GB
```

### EKS: Escalabilidad Ilimitada

```
Factores limitantes:
- Cuota de AWS               (aumentable)
- Presupuesto               (¡importante!)
- Cantidad de regiones      (ilimitadas)

Mínimo recomendado:
- 2 nodos para HA
- CPU: 2-4 cores por nodo
- RAM: 4-8 GB por nodo

Máximo escalable:
- 1000+ nodos en un cluster
- 100,000+ pods
- Multi-región posible
- Auto-scaling automático
```

---

## 🔐 Seguridad

### KIND

```yaml
# Seguridad básica (local)
- No requiere autenticación (es local)
- RBAC disponible pero típicamente no configurado
- Red local (no expuesta a internet)
- Sin TLS por defecto
```

### EKS

```yaml
# Seguridad enterprise
Security Groups: Restricción de tráfico
├── Control plane: Solo puertos necesarios
├── Nodes: Acceso desde ALB/NLB
└── Pods: Network policies

IAM Roles: Control de acceso granular
├── Node IAM role: Permisos de nodos
├── IRSA: IAM Roles for Service Accounts
└── Service accounts: Acceso granular

Encryption:
├── En tránsito: TLS 1.2+
├── En reposo: KMS
└── etcd: Encriptado por AWS

Network:
├── VPC con subnets públicas/privadas
├── NAT gateways para egress
└── VPC Flow Logs disponibles
```

---

## 📊 Arquitectura Comparativa

### KIND Cluster

```
┌─────────────────────────────────────────────────┐
│              Tu Máquina (macOS/Linux)           │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │       Docker Desktop                     │  │
│  │                                          │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │  KIND Container (mlops-cluster)   │ │  │
│  │  │  ─────────────────────────────────│ │  │
│  │  │  │ Kubernetes 1.28                │ │  │
│  │  │  │ ├─ Control Plane               │ │  │
│  │  │  │ └─ Worker Node                 │ │  │
│  │  │  │    ├─ mlflow pod               │ │  │
│  │  │  │    ├─ iris-api pod (x2)        │ │  │
│  │  │  │    ├─ evidently pod            │ │  │
│  │  │  │    └─ workspace pod            │ │  │
│  │  │  │                                 │ │  │
│  │  │  │ NodePort Services:             │ │  │
│  │  │  │ :30001 → MLflow                │ │  │
│  │  │  │ :30004 → Iris API              │ │  │
│  │  │  │ :30003 → Workspace             │ │  │
│  │  │  │ :30002 → Evidently             │ │  │
│  │  │  └────────────────────────────────┘ │  │
│  │  │           ↓                          │  │
│  │  │  localhost:30001, 30002, etc        │  │
│  │  └────────────────────────────────────┘  │
│  └──────────────────────────────────────────┘  │
│           ↓                                     │
│  http://localhost:30001 (MLflow)              │
└─────────────────────────────────────────────────┘
```

### EKS Cluster

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud (us-east-1)                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   VPC (10.0.0.0/16)                    │ │
│  │                                                        │ │
│  │  ┌─ Public Subnet (10.0.1.0/24) ─────────────────┐   │ │
│  │  │                                               │   │ │
│  │  │  ┌──────────────────────────────────────────┐│   │ │
│  │  │  │   Network Load Balancer                  ││   │ │
│  │  │  │   mlflow-elb.us-east-1.elb.amazonaws   ││   │ │
│  │  │  └──────────────────────────────────────────┘│   │ │
│  │  │                    ↓                          │   │ │
│  │  └────────────────────┼──────────────────────────┘   │ │
│  │                       │                              │ │
│  │  ┌─ Private Subnets ──┼────────────────────────────┐ │ │
│  │  │                    ↓                           │ │ │
│  │  │  ┌──────────────────────────────────────────┐ │ │ │
│  │  │  │    Kubernetes Control Plane (AWS)       │ │ │ │
│  │  │  │    (Managed - no acceso directo)        │ │ │ │
│  │  │  └──────────────────────────────────────────┘ │ │ │
│  │  │                                               │ │ │
│  │  │  ┌──────────────────────────────────────────┐ │ │ │
│  │  │  │         Worker Node 1 (t3.medium)       │ │ │ │
│  │  │  │  ├─ mlflow pod (1 replica)              │ │ │ │
│  │  │  │  ├─ evidently pod (1 replica)           │ │ │ │
│  │  │  │  └─ workspace pod (1 replica)           │ │ │ │
│  │  │  └──────────────────────────────────────────┘ │ │ │
│  │  │                                               │ │ │
│  │  │  ┌──────────────────────────────────────────┐ │ │ │
│  │  │  │         Worker Node 2 (t3.medium)       │ │ │ │
│  │  │  │  ├─ iris-api pod (replica 1)            │ │ │ │
│  │  │  │  └─ iris-api pod (replica 2)            │ │ │ │
│  │  │  └──────────────────────────────────────────┘ │ │ │
│  │  │                                               │ │ │
│  │  └───────────────────────────────────────────────┘ │ │
│  │                                                    │ │
│  │  LoadBalancer Services:                          │ │
│  │  - mlflow-elb → :5000 → MLflow pods              │ │
│  │  - iris-elb → :8000 → Iris API pods (LB)         │ │
│  │  - workspace-elb → :8888 → Workspace pods        │ │
│  │  - evidently-elb → :8000 → Evidently pods        │ │
│  │                                                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  ECR (Elastic Container Registry)                 │ │
│  │  - iris-api:latest                                │ │
│  │  - workspace:latest                               │ │
│  │  - (MLflow y Evidently de registros públicos)     │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Storage (EBS + RDS opcional)                     │ │
│  │  - MLflow data volume: 50GB                       │ │
│  │  - Evidently data volume: 20GB                    │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
└─────────────────────────────────────────────────────────┘
         ↓
http://mlflow-1234567890.us-east-1.elb.amazonaws.com:5000
http://iris-api-0987654321.us-east-1.elb.amazonaws.com:8000
http://workspace-0987654321.us-east-1.elb.amazonaws.com:8888
```

---

## 🔄 Proceso de Migración

```
1. Preparación (30 min)
   ├─ Instalar AWS CLI y eksctl
   ├─ Configurar credenciales AWS
   ├─ Revisar archivo terraform.tfvars
   └─ Verificar presupuesto

2. Provisión (20 min)
   ├─ terraform init
   ├─ terraform plan
   ├─ terraform apply
   └─ Esperar a que se cree EKS...

3. Imágenes (10 min)
   ├─ docker build iris-api
   ├─ docker build workspace
   ├─ docker push a ECR
   └─ Verificar en ECR

4. Despliegue (5 min)
   ├─ terraform apply (crea deployments)
   ├─ kubectl get pods (verificar ready)
   └─ kubectl get svc (obtener URLs)

5. Validación (10 min)
   ├─ Testear MLflow
   ├─ Testear Jupyter
   ├─ Testear API
   └─ Ejecutar notebook

6. Limpieza (5 min)
   ├─ terraform destroy
   ├─ Verificar AWS Console
   └─ Evitar cargos sorpresa
```

---

## 📚 Recursos Útiles

- [AWS EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [eksctl Documentation](https://eksctl.io/)
- [Kubernetes Comparison Chart](https://kubernetes.io/docs/setup/production-environment/)

---

## 🎯 Resumen

| Métrica | KIND | EKS |
|---------|------|-----|
| Costo | $0 | ~$160/mes |
| Setup | 5 min | 20 min |
| Escalabilidad | Limitada | Ilimitada |
| Production-ready | No | Sí |
| Ideal para | Desarrollo | Producción |
| Skill nivel | Principiante | Intermedio |
| Support | Comunidad | AWS Enterprise |

**Conclusión:** Usa KIND para aprender, usa EKS para producción.


