# 🚀 Clase 5: MLOps en AWS EKS

Migración completa de Kubernetes local (KIND) a AWS EKS (Elastic Kubernetes Service).

## 📋 Tabla de Contenidos

- [Inicio Rápido](#-inicio-rápido)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Pasos Detallados](#-pasos-detallados)
- [Troubleshooting](#-troubleshooting)
- [Costos](#-costos)
- [Recursos Útiles](#-recursos-útiles)

---

## 🎯 Inicio Rápido

```bash
# 1. Verificar herramientas
./scripts/check-prerequisites-aws.sh

# 2. Editar variables
vim infra/terraform.tfvars

# 3. Provisionar EKS (15-20 minutos)
./scripts/setup-eks.sh

# 4. Subir imágenes a ECR
./scripts/push-to-ecr.sh

# 5. Actualizar y desplegar
cd infra
terraform apply

# 6. Obtener URLs
kubectl get svc

# 7. IMPORTANTE: Destruir cuando termines
./scripts/destroy-eks.sh
```

---

## 📁 Estructura del Proyecto

```
clase-5/
├── 📄 COMIENZA_AQUI.txt              ← Lee esto primero
├── 📄 GUIA_MIGRACION_COMPLETA.md     ← Guía paso a paso
├── 📄 COMPARACION_KIND_VS_EKS.md     ← Diferencias técnicas
├── 📄 ARQUITECTURA_AWS.md            ← Diagramas de infraestructura
├── 📄 TROUBLESHOOTING_AWS.md         ← Solución de problemas
├── 📄 README.md                      ← Este archivo
│
├── 📁 infra/                         ← Terraform (Infrastructure as Code)
│   ├── provider.tf                   ← Configuración de providers
│   ├── variables.tf                  ← Variables de entrada
│   ├── terraform.tfvars              ← TUS VALORES (editar aquí)
│   ├── outputs.tf                    ← Información de salida
│   │
│   ├── networking.tf                 ← VPC, subnets, security groups
│   ├── iam-roles.tf                  ← Roles y políticas IAM
│   ├── eks.tf                        ← Clúster EKS y nodos
│   ├── ecr.tf                        ← Registros de contenedores
│   ├── storage.tf                    ← EBS volumes y storage classes
│   │
│   ├── mlflow.tf                     ← Deployment de MLflow
│   ├── evidently.tf                  ← Deployment de Evidently
│   ├── iris-api.tf                   ← Deployment de Iris API
│   └── workspace.tf                  ← Deployment de Jupyter
│
├── 📁 app_iris/                      ← API de predicción (igual a clase-4)
│   ├── Dockerfile
│   ├── main.py
│   ├── train.py
│   └── requirements.txt
│
├── 📁 app_workspace/                 ← Jupyter Lab (igual a clase-4)
│   ├── Dockerfile
│   └── requirements.txt
│
├── 📁 scripts/                       ← Automatización
│   ├── check-prerequisites-aws.sh    ← Verifica herramientas
│   ├── setup-eks.sh                  ← Provisiona EKS
│   ├── push-to-ecr.sh                ← Sube imágenes a ECR
│   └── destroy-eks.sh                ← Destruye todo (¡CUIDADO!)
│
└── 📁 notebooks/                     ← Material práctico (de clase-4)
    └── 01_simulacion.ipynb
```

---

## ⚙️ Requisitos Previos

### Herramientas Necesarias

```bash
# AWS CLI v2
brew install awscliv2

# eksctl
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# kubectl
brew install kubectl

# Terraform
brew install terraform

# Docker (ya lo tienes de clase-4)
# Ya debe estar instalado
```

### Credenciales de AWS

```bash
# Configura tus credenciales
aws configure

# Verifica que funciona
aws sts get-caller-identity
```

### Verificar Todo

```bash
# Ejecuta el script de verificación
./scripts/check-prerequisites-aws.sh

# Debería mostrar todo verde ✅
```

---

## 🚀 Pasos Detallados

### Paso 1: Configurar Variables de Terraform

Edita `infra/terraform.tfvars`:

```hcl
aws_region = "us-east-1"              # Tu región preferida
cluster_name = "mlops-cluster-prod"   # Nombre del clúster
node_instance_type = "t3.medium"      # Para desarrollo: t3.small
desired_capacity = 2                   # Número inicial de nodos
environment = "development"            # development, staging, production
owner = "tu-nombre"                    # Tu nombre
```

**⚠️ IMPORTANTE PARA COSTOS:**
- `t3.micro` o `t3.small` para desarrollo (~$10-20/mes)
- `t3.medium` para testing (~$30/mes)
- `t3.large` para producción (~$60+/mes)

### Paso 2: Provisionar EKS

```bash
# Ejecuta el setup completo
./scripts/setup-eks.sh

# Esto hará:
# 1. terraform init
# 2. terraform plan
# 3. terraform apply
# 4. Configura kubectl
# 5. Verifica nodos

# ⏳ Espera 15-20 minutos para que se cree el clúster
```

### Paso 3: Verificar el Cluster

```bash
# Ver nodos
kubectl get nodes

# Ver recursos de cluster
kubectl cluster-info

# Ver todos los pods
kubectl get pods
```

### Paso 4: Subir Imágenes a ECR

```bash
# Script automatizado
./scripts/push-to-ecr.sh

# O manualmente:
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

cd app_iris
docker build -t iris-api:latest .
docker tag iris-api:latest $ECR_URL/iris-api:latest
docker push $ECR_URL/iris-api:latest

cd ../app_workspace
docker build -t workspace:latest .
docker tag workspace:latest $ECR_URL/workspace:latest
docker push $ECR_URL/workspace:latest
```

### Paso 5: Actualizar Terraform con ECR URL

```bash
# Edita infra/terraform.tfvars
ecr_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com"

# Desplega servicios
cd infra
terraform apply
```

### Paso 6: Obtener URLs de Acceso

```bash
# Ver servicios con sus URLs
kubectl get svc

# O específicamente:
kubectl get svc mlflow-service -o wide
kubectl get svc iris-service -o wide
kubectl get svc workspace-service -o wide
```

### Paso 7: Acceder a los Servicios

```bash
# MLflow
http://<MLFLOW_EXTERNAL_IP>:5000

# Iris API
curl http://<IRIS_EXTERNAL_IP>:8000/health

# Jupyter Lab
http://<WORKSPACE_EXTERNAL_IP>:8888
```

### Paso 8: Limpiar (IMPORTANTE)

```bash
# Cuando termines, DEBE destruir todo
./scripts/destroy-eks.sh

# Verifica en AWS Console que no hay recursos
# - No EC2 instances
# - No Load Balancers
# - No EBS volumes
# - No RDS databases
```

---

## 🔍 Troubleshooting

### Problema: "Pod stuck in ImagePullBackOff"

```bash
# Ver el error
kubectl describe pod <POD_NAME>

# Soluciones:
# 1. Verificar que la imagen está en ECR
aws ecr describe-images --repository-name iris-api

# 2. Verificar que ECR URL es correcta en Terraform
grep "ecr_url" infra/terraform.tfvars

# 3. Reconstruir y subir imagen
./scripts/push-to-ecr.sh
```

### Problema: "LoadBalancer stuck in pending"

```bash
# Es normal que tarde 1-2 minutos
kubectl get svc -w

# Si sigue pending después de 3 minutos:
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Recrear el service
kubectl delete svc mlflow-service
cd infra
terraform apply
```

### Problema: "Nodos no están ready"

```bash
# Ver estado de nodos
kubectl get nodes -o wide

# Ver logs de nodos
kubectl describe node <NODE_NAME>

# Esperar a que terminen de inicializarse (puede tomar 5-10 min)
```

### Problema: "Insufficient capacity"

```bash
# Cambiar región o tipo de instancia
vim infra/terraform.tfvars

# Cambiar de:
# aws_region = "us-east-1"
# A:
# aws_region = "us-west-2"

# O cambiar tipo:
# node_instance_type = "t3.small"

# Aplicar cambios
terraform apply
```

Para más ayuda, ver: **TROUBLESHOOTING_AWS.md**

---

## 💰 Costos

### Estimación Mensual

| Componente | Cantidad | Costo/mes |
|-----------|----------|----------|
| EKS Control Plane | 1 | $73 |
| EC2 t3.medium | 2 | $60 |
| Load Balancer | 3 | $20 |
| EBS Storage | 70GB | $5 |
| Data Transfer | ~ | $5 |
| **TOTAL** | | **~$160** |

### Cómo Reducir Costos

```hcl
# 1. Usar instancia más pequeña
node_instance_type = "t3.micro"      # ~$10/mes
# O
node_instance_type = "t3.small"      # ~$20/mes

# 2. Usar menos nodos
desired_capacity = 1                  # Inicial mínimo

# 3. Usar Spot instances (50% descuento)
capacity_type = "SPOT"                # En eks.tf

# 4. Usar free tier (1 año gratis)
# Si es tu primer AWS account

# 5. IMPORTANTE: Destruir cuando no uses
./scripts/destroy-eks.sh              # $0 si no hay recursos
```

**⚠️ RECUERDA: Cada recurso corriendo tiene costo. No olvides destruir cuando termines.**

---

## 📚 Comparación: KIND vs EKS

| Aspecto | KIND | EKS |
|---------|------|-----|
| Ubicación | Local | Cloud (AWS) |
| Costo | $0 | ~$160/mes |
| Setup | 5 min | 20 min |
| Escalabilidad | 1-3 nodos | 1-1000+ nodos |
| Alta Disponibilidad | Limitada | Completa |
| Uso Ideal | Desarrollo | Producción |

Ver: **COMPARACION_KIND_VS_EKS.md** para análisis detallado.

---

## 🏗️ Arquitectura

La infraestructura en AWS incluye:

```
Internet
    ↓
┌─────────────────────────────────────────┐
│ AWS VPC (10.0.0.0/16)                  │
├─────────────────────────────────────────┤
│ Public Subnets (con Load Balancers)     │
├─────────────────────────────────────────┤
│ Private Subnets (con EC2 Nodes)         │
│ ├─ Node 1 (t3.medium)                   │
│ │  ├─ MLflow pod                        │
│ │  ├─ Evidently pod                     │
│ │  └─ Workspace pod                     │
│ └─ Node 2 (t3.medium)                   │
│    ├─ Iris API pod (replica 1)          │
│    └─ Iris API pod (replica 2)          │
├─────────────────────────────────────────┤
│ EKS Control Plane (managed by AWS)      │
├─────────────────────────────────────────┤
│ ECR (imágenes privadas)                 │
├─────────────────────────────────────────┤
│ EBS Volumes (almacenamiento persistente)│
└─────────────────────────────────────────┘
```

Ver: **ARQUITECTURA_AWS.md** para diagramas completos.

---

## 🔑 Comandos Útiles

```bash
# Ver estado del cluster
kubectl cluster-info
kubectl get nodes -o wide

# Ver pods
kubectl get pods
kubectl get pods -w           # En tiempo real
kubectl describe pod <NAME>

# Ver servicios
kubectl get svc
kubectl get svc -w            # En tiempo real

# Logs
kubectl logs deployment/iris-api
kubectl logs deployment/iris-api -f    # En tiempo real

# Escalar
kubectl scale deployment iris-api --replicas=5

# Port forward
kubectl port-forward svc/mlflow-service 5000:5000

# Exec en pod
kubectl exec -it pod/<NAME> -- /bin/bash

# AWS
aws eks describe-cluster --name mlops-cluster-prod
aws ecr describe-repositories
aws ec2 describe-instances
```

---

## 📖 Documentación

- **COMIENZA_AQUI.txt** - Introducción general
- **GUIA_MIGRACION_COMPLETA.md** - Paso a paso detallado
- **COMPARACION_KIND_VS_EKS.md** - Análisis técnico
- **ARQUITECTURA_AWS.md** - Diagramas y componentes
- **TROUBLESHOOTING_AWS.md** - Solución de problemas
- **README.md** - Este archivo

---

## 🎓 Conceptos Clave

### 1. EKS (Elastic Kubernetes Service)
- Kubernetes gestionado por AWS
- Control plane manejado automáticamente
- Worker nodes que tú provisiones

### 2. ECR (Elastic Container Registry)
- Registro privado de Docker
- Almacena tus imágenes (iris-api, workspace)
- Acceso seguro desde EKS

### 3. VPC (Virtual Private Cloud)
- Red virtual aislada en AWS
- Subnets públicas para load balancers
- Subnets privadas para nodos (más seguro)

### 4. IAM (Identity and Access Management)
- Roles y permisos granulares
- IRSA: IAM Roles for Service Accounts
- Least privilege: mínimos permisos necesarios

### 5. EBS (Elastic Block Storage)
- Almacenamiento persistente
- Los datos no se pierden al reiniciar pod
- Usado por MLflow y Evidently

---

## 🆘 Soporte

Si tienes problemas:

1. **Revisa TROUBLESHOOTING_AWS.md**
2. **Ejecuta:** `kubectl describe pod <NAME>`
3. **Ejecuta:** `kubectl logs deployment/<NAME>`
4. **Revisa AWS Console** para errores de infraestructura
5. **Pregunta a tu instructor**

---

## ✅ Checklist de Finalización

```
Antes de comenzar:
☐ Herramientas instaladas (./scripts/check-prerequisites-aws.sh)
☐ Credenciales AWS configuradas (aws configure)
☐ Variables de Terraform editadas (infra/terraform.tfvars)

Después de terraform apply:
☐ Cluster EKS creado
☐ Nodos ready (kubectl get nodes)
☐ Imágenes en ECR
☐ Pods running (kubectl get pods)
☐ Load balancers creados (kubectl get svc)

Después de desplegar servicios:
☐ MLflow accesible
☐ Iris API respondiendo
☐ Jupyter Lab funcionando
☐ Notebook ejecutado

Limpieza:
☐ terraform destroy ejecutado
☐ AWS Console verificado (sin recursos)
☐ Factura revisada (sin cargos sorpresa)
```

---

## 🎉 ¡Felicidades!

Ya tienes MLOps completo en la nube con AWS EKS. 

**Próximos pasos para producción:**

1. Agregar HTTPS/TLS con ACM
2. Usar RDS para base de datos persistente
3. Implementar CI/CD con CodePipeline
4. Agregar monitoreo con CloudWatch/Prometheus
5. Escalar automáticamente con Autoscaler
6. Implementar disaster recovery

---

**Creado para: Clase 5 - MLOps en AWS EKS 🚀**


