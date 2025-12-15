# 🚀 Guía Completa: Migración de KIND a AWS EKS

## 📋 Tabla de Contenidos
1. [Preparación Inicial](#preparación-inicial)
2. [Configuración de AWS](#configuración-de-aws)
3. [Provisionamiento de EKS](#provisionamiento-de-eks)
4. [Migración de Imágenes](#migración-de-imágenes)
5. [Despliegue de Servicios](#despliegue-de-servicios)
6. [Validación y Pruebas](#validación-y-pruebas)
7. [Monitoreo y Costos](#monitoreo-y-costos)
8. [Limpieza y Destrucción](#limpieza-y-destrucción)

---

## Preparación Inicial

### Paso 1: Instalar Herramientas Necesarias

```bash
# 1. AWS CLI v2
brew install awscliv2
aws --version

# 2. eksctl (herramienta oficial de EKS)
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
eksctl version

# 3. kubectl (probablemente ya lo tienes)
brew install kubectl
kubectl version --client

# 4. Terraform (probablemente ya lo tienes)
terraform version
```

### Paso 2: Verificar Prerrequisitos

```bash
# Ejecuta el script de verificación
./scripts/check-prerequisites-aws.sh

# Debería mostrar:
# ✅ AWS CLI instalado
# ✅ eksctl instalado
# ✅ kubectl instalado
# ✅ Terraform instalado
# ✅ Docker instalado
```

### Paso 3: Verificar Credenciales de AWS

```bash
# Configura tus credenciales (si no lo has hecho)
aws configure

# Verificar que funciona
aws sts get-caller-identity

# Output esperado:
# {
#     "UserId": "AIDAJ...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/tu-usuario"
# }
```

---

## Configuración de AWS

### Paso 4: Configurar Variables de Terraform

Edita `infra/terraform.tfvars`:

```hcl
# Región de AWS
aws_region = "us-east-1"  # O la que prefieras

# Nombre del clúster
cluster_name = "mlops-cluster-prod"

# Versión de Kubernetes
kubernetes_version = "1.28"

# Tipo y cantidad de nodos
node_instance_type = "t3.medium"  # Para desarrollo: t3.small o t3.micro
desired_capacity   = 2            # Número de nodos iniciales
min_capacity       = 1
max_capacity       = 4

# VPC CIDR
vpc_cidr = "10.0.0.0/16"

# Tags para organizar recursos
environment = "development"
project     = "mlops-clase5"
owner       = "tu-nombre"
```

### Paso 5: Entender la Estructura de Terraform

```
infra/
├── provider.tf          # AWS provider config
├── variables.tf         # Variables de entrada
├── outputs.tf           # Variables de salida
├── eks.tf              # Clúster EKS y nodos
├── networking.tf       # VPC, subnets, security groups
├── iam-roles.tf        # Roles y políticas IAM
├── ecr.tf              # Repositorios Docker privados
├── mlflow.tf           # Deployment MLflow
├── evidently.tf        # Deployment Evidently
├── iris-api.tf         # Deployment Iris API
├── workspace.tf        # Deployment Jupyter
└── terraform.tfvars    # Tus valores (NO commitear)
```

---

## Provisionamiento de EKS

### Paso 6: Inicializar Terraform

```bash
cd infra
terraform init

# Output esperado:
# Terraform has been successfully configured!
```

### Paso 7: Revisar el Plan

```bash
terraform plan

# Mostrará todos los recursos que se van a crear
# - VPC y subnets
# - Security groups
# - EKS cluster
# - Nodos (EC2 instances)
# - Load Balancer
# - IAM roles
```

### Paso 8: Aplicar Configuración

```bash
terraform apply

# Ingresa "yes" cuando se pregunte
# Esto va a tomar ~15-20 minutos para crear el clúster
```

### Paso 9: Configurar kubeconfig

```bash
# Actualizar kubeconfig para acceder al clúster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name mlops-cluster-prod

# Verificar acceso
kubectl get nodes

# Output esperado:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-100.ec2.internal   Ready    <none>   2m    v1.28.0
# ip-10-0-2-200.ec2.internal   Ready    <none>   2m    v1.28.0
```

---

## Migración de Imágenes

### Paso 10: Crear Repositorios en ECR

```bash
# Los repositorios se crean automáticamente con Terraform,
# pero puedes crearlos manualmente si quieres

aws ecr create-repository --repository-name iris-api --region us-east-1
aws ecr create-repository --repository-name workspace --region us-east-1
```

### Paso 11: Obtener Credenciales de ECR

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### Paso 12: Construir y Subir Imágenes

```bash
# Obtén la URL del repositorio ECR
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 1. Iris API
cd ../app_iris
docker build -t iris-api:latest .
docker tag iris-api:latest $ECR_URL/iris-api:latest
docker push $ECR_URL/iris-api:latest

# 2. Workspace (Jupyter)
cd ../app_workspace
docker build -t workspace:latest .
docker tag workspace:latest $ECR_URL/workspace:latest
docker push $ECR_URL/workspace:latest

# 3. MLflow (si quieres usar imagen custom)
# Si no, Terraform usará ghcr.io/mlflow/mlflow:v2.10.0

# 4. Evidently (si quieres usar imagen custom)
# Si no, Terraform usará evidently/evidently-service:latest
```

### Paso 13: Verificar Imágenes en ECR

```bash
# Listar repositorios
aws ecr describe-repositories --region us-east-1

# Listar imágenes en un repositorio
aws ecr describe-images --repository-name iris-api --region us-east-1
```

---

## Despliegue de Servicios

### Paso 14: Actualizar Terraform con URLs de ECR

En `infra/iris-api.tf` y `infra/workspace.tf`, actualiza las URLs:

```hcl
locals {
  iris_api_image = "${var.ecr_url}/iris-api:latest"
  workspace_image = "${var.ecr_url}/workspace:latest"
}
```

### Paso 15: Aplicar Deployments

```bash
cd infra
terraform apply

# Verifica que se crean los deployments
kubectl get deployments

# Output esperado:
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# mlflow     1/1     1            1           2m
# evidently  1/1     1            1           2m
# iris-api   2/2     2            2           2m
# workspace  1/1     1            1           2m
```

### Paso 16: Verificar Pods

```bash
# Ver todos los pods
kubectl get pods

# Ver pods con más detalles
kubectl get pods -o wide

# Ver logs de un pod
kubectl logs -l app=iris-api
kubectl logs -l app=workspace
```

### Paso 17: Obtener URLs de Servicios

```bash
# Obtener Load Balancer URLs
kubectl get svc

# Output esperado:
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP                        PORT(S)
# mlflow-service    LoadBalancer   10.100.200.10   a1b2c3d4-123456789.us-east-1.e... 5000:31234/TCP
# iris-service      LoadBalancer   10.100.200.11   a1b2c3d4-123456789.us-east-1.e... 8000:31235/TCP
# workspace-service LoadBalancer   10.100.200.12   a1b2c3d4-123456789.us-east-1.e... 8888:31236/TCP
```

---

## Validación y Pruebas

### Paso 18: Testear MLflow

```bash
# Obtén la URL del LoadBalancer de MLflow
MLFLOW_URL=$(kubectl get svc mlflow-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Abre en el navegador
echo "http://$MLFLOW_URL:5000"
```

### Paso 19: Testear Jupyter Lab

```bash
# Obtén la URL del LoadBalancer de Workspace
WORKSPACE_URL=$(kubectl get svc workspace-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Abre en el navegador
echo "http://$WORKSPACE_URL:8888"
```

### Paso 20: Testear API

```bash
# Obtén la URL del LoadBalancer de Iris API
IRIS_URL=$(kubectl get svc iris-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Health check
curl http://$IRIS_URL:8000/health

# Predicción
curl -X POST http://$IRIS_URL:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'
```

### Paso 21: Ejecutar Notebook de Simulación

```bash
# Abre Jupyter Lab en el navegador
# Copia el notebook de clase-4: 01_simulacion.ipynb
# Modifica las URLs para apuntar a los Load Balancers
# Ejecuta el notebook
```

---

## Monitoreo y Costos

### Paso 22: Monitorear Recursos

```bash
# Ver nodos
kubectl get nodes -o wide

# Ver uso de recursos
kubectl top nodes

# Ver pods y su consumo
kubectl top pods

# Ver eventos
kubectl get events

# Ver logs de un deployment
kubectl logs deployment/mlflow

# Port forward (si prefieres acceso local)
kubectl port-forward svc/mlflow-service 5000:5000
# Ahora: http://localhost:5000
```

### Paso 23: Verificar Costos en AWS

```bash
# En AWS Console:
# 1. Ve a EC2 Dashboard
# 2. Verifica instancias corriendo
# 3. Ve a EKS Dashboard
# 4. Verifica nodos del clúster
# 5. Ve a Cost Explorer para estimar costos
```

### Paso 24: Escalar Nodos si es Necesario

```bash
# Aumentar número de nodos
terraform apply -var="desired_capacity=3"

# Verificar
kubectl get nodes
```

---

## Limpieza y Destrucción

### ⚠️ IMPORTANTE: Destruir Recursos cuando Termines

```bash
# Destruir TODO (¡CUIDADO!)
cd infra
terraform destroy

# Confirma escribiendo "yes"

# Verificar en AWS Console que todo se haya eliminado
```

### Paso 25: Script Automatizado de Destrucción

```bash
# Opcionalmente, usa el script
./scripts/destroy-eks.sh

# Verifica nuevamente en AWS Console
```

### Paso 26: Evitar Sorpresas de Costos

```bash
# Después de terraform destroy:
# 1. Ve a AWS Console
# 2. Verifica EC2 - No debe haber instancias
# 3. Verifica RDS - No debe haber bases de datos
# 4. Verifica ELB - No debe haber load balancers
# 5. Verifica EBS - No debe haber volúmenes
```

---

## 🎯 Checklist de Migración

```
Preparación:
☐ AWS CLI configurado
☐ eksctl instalado
☐ Credenciales de AWS verificadas
☐ Regiones de AWS elegidas

Configuración:
☐ terraform.tfvars completado
☐ terraform plan revisado
☐ Presupuesto de AWS verificado

Provisión:
☐ terraform apply ejecutado
☐ Clúster EKS creado (~15-20 min)
☐ kubeconfig actualizado
☐ kubectl get nodes funciona

Imágenes:
☐ Imágenes construidas localmente
☐ ECR repositorios creados
☐ Imágenes subidas a ECR
☐ Docker login a ECR exitoso

Despliegue:
☐ Deployments creados
☐ Pods running y ready
☐ Services con LoadBalancer
☐ URLs accesibles

Validación:
☐ MLflow accesible
☐ Jupyter Lab accesible
☐ API respondiendo
☐ Notebook ejecutado

Limpieza:
☐ terraform destroy ejecutado
☐ AWS Console verificado (sin recursos)
☐ Ningún cargo inesperado
```

---

## 💡 Tips y Mejores Prácticas

### 1. Usar Namespaces

```bash
# Crear namespace para MLOps
kubectl create namespace mlops
kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: mlops
EOF

# Desplegar en namespace específico
# (Actualizar Terraform para usar namespaces)
```

### 2. Configurar Autoscaling

```bash
# Instalar Cluster Autoscaler
eksctl create addon --cluster mlops-cluster-prod \
  --addon vpc-cni --addon-version latest

# Configurar autoscaling de pods (HPA)
kubectl apply -f - << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: iris-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: iris-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
```

### 3. Usar Persistent Volumes

```bash
# Terraform ya crea storage, pero aquí está el concepto:
# Los datos de MLflow y Evidently se guardan en EBS
# No son efímeros como en KIND
```

### 4. Implementar Secrets

```bash
# Crear secret de credenciales
kubectl create secret generic mlflow-creds \
  --from-literal=username=admin \
  --from-literal=password=securepassword

# Usar en deployment
env:
- name: MLFLOW_TRACKING_USERNAME
  valueFrom:
    secretKeyRef:
      name: mlflow-creds
      key: username
```

### 5. Monitorear con CloudWatch

```bash
# Los logs de EKS se envían a CloudWatch
# Ve a CloudWatch en AWS Console:
# /aws/eks/mlops-cluster-prod/cluster

# O usa kubectl:
kubectl logs -l app=iris-api
```

---

## 🆘 Errores Comunes y Soluciones

### Error: "No credentials provided"

```bash
aws configure
# Ingresa Access Key ID y Secret Access Key
```

### Error: "Pod stuck in ImagePullBackOff"

```bash
# Problema: Imagen no encontrada en ECR
kubectl describe pod <POD_NAME>

# Solución: Verificar URL de imagen en Terraform
# y asegurar que la imagen existe en ECR
```

### Error: "Pending nodes in cluster"

```bash
# Problema: No hay capacidad en nodos
# Solución: Escalados o cambiar tipo de instancia
```

### Costo inesperado

```bash
# Problema: Recursos olvidados
# Solución: terraform destroy + verificar AWS Console
```

---

## 📊 Siguiente Paso: Producción

Una vez que domines EKS:

1. **Agregar HTTPS/TLS** con ACM
2. **Usar RDS** para base de datos (no local)
3. **Implementar CI/CD** con CodePipeline
4. **Usar Route53** para DNS
5. **Agregar WAF** (Web Application Firewall)
6. **Configurar backup** automático
7. **Implementar logging** centralizado con ELK/Splunk

---

**¡Felicidades! Ya estás en la nube con AWS EKS 🚀**


