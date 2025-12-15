# 🆘 Troubleshooting: Guía de Solución de Problemas AWS EKS

## 🔴 Errores Comunes y Soluciones

### 1. Error: "No credentials provided"

**Síntoma:**
```
Error: No valid credential sources found
```

**Causa:** AWS CLI no está configurado

**Solución:**
```bash
# Opción 1: Configurar interactivamente
aws configure
# Ingresa: Access Key ID, Secret Access Key, región, formato

# Opción 2: Usar variables de entorno
export AWS_ACCESS_KEY_ID="tu-access-key"
export AWS_SECRET_ACCESS_KEY="tu-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verificar
aws sts get-caller-identity
```

---

### 2. Error: "terraform init failed"

**Síntoma:**
```
Error: Failed to download module
```

**Causa:** Problemas de conectividad o versión incompatible

**Solución:**
```bash
# Actualizar Terraform
brew upgrade terraform

# Limpiar caché
rm -rf .terraform
rm -rf .terraform.lock.hcl

# Reintentar
terraform init

# Si sigue fallando, especificar versión
terraform init -upgrade
```

---

### 3. Error: "InvalidParameterValue - Role is invalid"

**Síntoma:**
```
Error: InvalidParameterValue: Invalid role ARN
```

**Causa:** Rol IAM no existe o permisos incorrectos

**Solución:**
```bash
# Verificar que el rol existe
aws iam get-role --role-name eks-node-role

# Si no existe, Terraform debería crearlo automáticamente
# Verificar que terraform.tfvars está correcto
cat infra/terraform.tfvars

# Limpiar y reintentar
terraform destroy -auto-approve
terraform apply
```

---

### 4. Error: "Insufficient capacity"

**Síntoma:**
```
Error: Could not launch instances
Reason: We currently do not have sufficient capacity
```

**Causa:** AWS no tiene disponibilidad de instancias en esa AZ/región

**Solución:**
```bash
# Opción 1: Cambiar región
# Edita: infra/terraform.tfvars
aws_region = "us-west-2"

# Opción 2: Cambiar tipo de instancia
node_instance_type = "t3.small"  # en lugar de t3.medium

# Opción 3: Esperar y reintentar
terraform apply
```

---

### 5. Error: "kubectl: connection refused"

**Síntoma:**
```
Unable to connect to the server: dial tcp 127.0.0.1:6443: connect: connection refused
```

**Causa:** kubeconfig no está configurado

**Solución:**
```bash
# Actualizar kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name mlops-cluster-prod

# Verificar que está configurado
cat ~/.kube/config

# Prueba de conexión
kubectl cluster-info

# Si sigue fallando, verificar que el cluster existe
aws eks describe-cluster --name mlops-cluster-prod --region us-east-1
```

---

### 6. Error: "ImagePullBackOff"

**Síntoma:**
```
Warning: Failed to pull image "iris-api:latest": Error response from daemon: repository not found
```

**Causa:** Imagen no está en ECR o URL incorrecta

**Solución:**
```bash
# 1. Verificar que la imagen existe en ECR
aws ecr describe-images \
  --repository-name iris-api \
  --region us-east-1

# 2. Si no existe, construir y subir
cd app_iris
docker build -t iris-api:latest .

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
docker tag iris-api:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/iris-api:latest

# 3. Hacer login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 4. Subir imagen
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/iris-api:latest

# 5. Verificar en Terraform que el URL es correcto
grep "iris_api_image" infra/iris-api.tf
```

---

### 7. Error: "Pod running pero acceso denegado"

**Síntoma:**
```
curl: (7) Failed to connect to mlflow-xxxxx.elb.amazonaws.com:5000
connection timeout
```

**Causa:** Security group no permite tráfico

**Solución:**
```bash
# 1. Verificar security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=mlops*" \
  --region us-east-1

# 2. Verificar inbound rules
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=sg-xxxxx"

# 3. Verificar que los nodos estén en el security group correcto
kubectl get nodes
aws ec2 describe-instances --region us-east-1

# 4. Si falta regla, agregar manualmente:
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 5000 \
  --cidr 0.0.0.0/0 \
  --region us-east-1

# 5. Reiniciar pod
kubectl rollout restart deployment/mlflow
```

---

### 8. Error: "LoadBalancer stuck in pending"

**Síntoma:**
```
kubectl get svc
NAME      TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)
mlflow    LoadBalancer   10.100.10.1   <pending>     5000:31234/TCP
```

**Causa:** ALB controller no creó el load balancer

**Solución:**
```bash
# 1. Verificar logs del controlador
kubectl logs -n kube-system -l app=aws-load-balancer-controller

# 2. Instalar/actualizar ALB controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system

# 3. Forzar recrear el service
kubectl delete svc mlflow-service
cd infra
terraform apply

# 4. Esperar (~2 min)
kubectl get svc -w
```

---

### 9. Error: "Pods no pueden acceder a ECR"

**Síntoma:**
```
Warning: Failed to pull image from ECR
ImagePullBackOff
```

**Causa:** Node IAM role no tiene permisos a ECR

**Solución:**
```bash
# 1. Verificar que el node role tiene AmazonEC2ContainerRegistryReadOnly
ROLE_NAME=$(aws eks describe-nodegroup \
  --cluster-name mlops-cluster-prod \
  --nodegroup-name mlops-nodegroup \
  --region us-east-1 \
  --query 'nodegroup.nodeRole' --output text | awk -F'/' '{print $NF}')

aws iam list-attached-role-policies --role-name $ROLE_NAME

# 2. Si no está, agregar política
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# 3. Reiniciar nodos (cuidado: causa downtime)
kubectl drain <NODE_NAME> --ignore-daemonsets
# Esperar a que se reemplace automáticamente
```

---

### 10. Error: "Pod evicted"

**Síntoma:**
```
kubectl describe pod/iris-api-xxxxx
Status: Failed
Reason: Evicted
Message: The node had condition: MemoryPressure
```

**Causa:** Nodo sin memoria disponible

**Solución:**
```bash
# 1. Ver uso de memoria
kubectl top nodes
kubectl top pods

# 2. Opción A: Aumentar capacidad de nodos
# Edita: infra/terraform.tfvars
desired_capacity = 3  # en lugar de 2

# 3. Opción B: Usar instancia más grande
node_instance_type = "t3.large"  # en lugar de t3.medium

# 4. Aplicar cambios
terraform apply

# 5. Reducir límites de pods si es necesario
# Edita: infra/iris-api.tf (reduce memory limits)
```

---

### 11. Error: "Terraform destroy no limpia recursos"

**Síntoma:**
```
terraform destroy -auto-approve
# Pero en AWS Console siguen habiendo recursos
```

**Causa:** Algunos recursos tienen dependencias

**Solución:**
```bash
# 1. Verificar qué quedó
terraform state list
terraform state show

# 2. Limpiar manualmente por tipo de recurso
aws elb describe-load-balancers --region us-east-1
aws elb delete-load-balancer --load-balancer-name <NAME> --region us-east-1

aws ec2 describe-volumes --region us-east-1
aws ec2 delete-volume --volume-id vol-xxxxx --region us-east-1

# 3. Verificar en AWS Console:
# - EC2 Dashboard
# - RDS Database
# - ELB/ALB
# - EBS Volumes
# - VPC

# 4. Si todo está limpio, borrar el state
rm -rf .terraform
rm terraform.tfstate*
```

---

### 12. Error: "DRY RUN: no se aplica nada"

**Síntoma:**
```
terraform plan -out=tfplan
terraform apply tfplan
# Pero nada ocurre
```

**Solución:**
```bash
# No usar tfplan, aplicar directamente
terraform apply

# O usar auto-approve (menos seguro)
terraform apply -auto-approve
```

---

## ⚠️ Errores Relacionados a Costos

### "¡Mi factura de AWS es muy alta!"

**Causas comunes:**
1. Cluster no fue destruido
2. Volúmenes EBS no fueron eliminados
3. Load Balancers siguen corriendo
4. Transferencia de datos de egress

**Solución Rápida:**
```bash
# Destruir TODO inmediatamente
cd infra
terraform destroy -auto-approve

# Verificar AWS Console que esté limpio
# - No EC2 instances
# - No Load Balancers
# - No EBS volumes (o desmontar)
# - No RDS databases

# Esperar a que se procese (puede tomar horas)
# y revisar la factura siguiente
```

**Prevención:**
```bash
# Antes de comenzar a experimentar:
1. Setup AWS Billing Alerts
2. Configurar presupuesto máximo
3. Usar free tier si es disponible
4. SIEMPRE destroyer después de practicar
```

---

## 🔍 Debugging Avanzado

### Ver logs de un pod

```bash
# Logs en tiempo real
kubectl logs -f deployment/iris-api

# Últimos 100 líneas
kubectl logs -n default deployment/iris-api --tail=100

# Logs desde hace 1 hora
kubectl logs deployment/iris-api --since=1h

# Logs de todas las réplicas
kubectl logs deployment/iris-api --all-containers=true
```

### Describir un pod en problemas

```bash
# Ver detalles completos
kubectl describe pod/<POD_NAME>

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp'

# Ver estado de condiciones
kubectl describe node/<NODE_NAME>
```

### Port forward para debugging

```bash
# Acceso local a un pod
kubectl port-forward pod/mlflow-xxxxx 5000:5000

# Acceso en otra terminal
curl localhost:5000

# Port forward a un service
kubectl port-forward svc/iris-service 8000:8000
```

### Ejecutar comandos en un pod

```bash
# Bash shell en un pod
kubectl exec -it pod/iris-api-xxxxx -- /bin/bash

# Ejecutar comando específico
kubectl exec pod/iris-api-xxxxx -- curl localhost:8000/health
```

---

## ✅ Checklist de Diagnóstico

```
□ AWS CLI configurado
  → aws sts get-caller-identity

□ Credenciales válidas
  → aws iam get-user

□ Terraform versión correcta
  → terraform version

□ Cluster EKS existe
  → aws eks describe-cluster --name mlops-cluster-prod

□ kubeconfig configurado
  → kubectl cluster-info

□ Nodos ready
  → kubectl get nodes (STATUS: Ready)

□ Pods running
  → kubectl get pods (STATUS: Running)

□ Services tienen External-IP
  → kubectl get svc (EXTERNAL-IP: <IP>, no <pending>)

□ Puedo acceder a servicios
  → curl http://<EXTERNAL-IP>:5000

□ No hay pods evicted
  → kubectl get pods (no "Evicted" status)

□ Storage disponible
  → kubectl top nodes
```

---

## 📞 Recursos de Soporte

1. **AWS Support**: https://aws.amazon.com/support/
2. **EKS FAQ**: https://aws.amazon.com/eks/faq/
3. **Kubernetes Troubleshooting**: https://kubernetes.io/docs/tasks/debug/
4. **Terraform AWS Provider Issues**: https://github.com/hashicorp/terraform-provider-aws/issues
5. **Community**: AWS Slack, Reddit r/aws, StackOverflow

---

## 🎯 Resumen Quick-Fix

| Problema | Comando Rápido |
|----------|---|
| Sin credenciales | `aws configure` |
| Pod no inicia | `kubectl describe pod <NAME>` |
| Servicio no accesible | `kubectl get svc` (esperar External-IP) |
| Memoria completa | `terraform apply -var="desired_capacity=3"` |
| Imagen no encontrada | `aws ecr describe-images --repository-name iris-api` |
| Destruir todo | `terraform destroy -auto-approve` |
| Ver logs | `kubectl logs -f deployment/iris-api` |
| Diagnosticar nodo | `kubectl describe node <NODE_NAME>` |

---

**¡Esperamos no necesites este archivo, pero aquí está! 🚀**


