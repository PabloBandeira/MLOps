# 🚀 Scripts de Automatización - Clase 5

Todos los scripts necesarios para provisionar y destruir EKS automáticamente.

## 📋 Scripts Disponibles

### 1️⃣ `check-prerequisites-aws.sh`
**Verifica que tengas todas las herramientas instaladas**

```bash
./scripts/check-prerequisites-aws.sh
```

✅ Verifica:
- AWS CLI instalado
- eksctl instalado
- kubectl instalado
- Terraform instalado
- Docker instalado
- Credenciales AWS válidas

**Cuándo usar:** Al inicio, antes de todo

---

### 2️⃣ `setup-eks.sh`
**Provisiona el cluster EKS completo (15-20 min)**

```bash
./scripts/setup-eks.sh
```

✅ Hace:
1. `terraform init`
2. `terraform plan`
3. `terraform apply` (crea infraestructura)
4. Configura kubeconfig
5. Verifica nodos

⏳ Espera pasivamente (15-20 minutos)

**Cuándo usar:** Después de editar `terraform.tfvars`

---

### 3️⃣ `push-to-ecr.sh`
**Construye y sube imágenes a ECR (5-10 min)**

```bash
./scripts/push-to-ecr.sh
```

✅ Hace:
1. Hace login a ECR
2. Construye iris-api:latest
3. Construye workspace:latest
4. Sube ambas a ECR

**Cuándo usar:** Después de `setup-eks.sh`

---

### 4️⃣ `destroy-eks.sh`
**Destruye infraestructura EKS (5-10 min)**

```bash
./scripts/destroy-eks.sh
```

✅ Hace:
1. Pide confirmación (seguridad)
2. Ejecuta `terraform destroy`
3. Verifica en AWS Console

⚠️ Borra:
- VPC
- Subnets
- EKS Cluster
- Nodos EC2
- Load Balancers
- Volúmenes EBS

**Cuándo usar:** Cuando terminies de experimentar

---

### 5️⃣ `total-cleanup.sh` ⭐ NUEVO
**Destrucción TOTAL - Borra absolutamente TODOOOOOO (10 min)**

```bash
./scripts/total-cleanup.sh
```

✅ Hace:
1. `terraform destroy -auto-approve`
2. Borra repositorios ECR (iris-api, workspace)
3. Limpia imágenes huérfanas
4. Verifica cada aspecto de AWS
5. Muestra tablas de lo que quedó

✅ Borra:
- ✅ VPC
- ✅ Subnets
- ✅ Security Groups
- ✅ EKS Cluster
- ✅ Nodos EC2
- ✅ Load Balancers
- ✅ Volúmenes EBS
- ✅ ECR Repositories
- ✅ IAM Roles
- ✅ Absolutamente TODO

⚠️ **ADVERTENCIA CRÍTICA:**
- Pide confirmación triple (seguridad máxima)
- NO se puede deshacer
- Verifica que NADA queda en AWS

**Cuándo usar:** Limpieza final de la cuenta

---

## 🔄 Flujo Completo de Ejecución

```bash
# 1. Verificar herramientas (1 min)
./scripts/check-prerequisites-aws.sh

# 2. Editar variables
vim infra/terraform.tfvars

# 3. Provisionar (20 min - espera pasivamente)
./scripts/setup-eks.sh

# 4. Sube imágenes (10 min)
./scripts/push-to-ecr.sh

# 5. Edita ECR URL
vim infra/terraform.tfvars

# 6. Despliega servicios (10 min)
cd infra && terraform apply && cd ..

# 7. Experimenta con kubectl
kubectl get svc
kubectl get pods

# 8. LIMPIEZA FINAL (Elige una):

# Opción A: Destrucción estándar
./scripts/destroy-eks.sh

# Opción B: Destrucción TOTAL (asegura limpieza completa)
./scripts/total-cleanup.sh
```

---

## 📊 Diferencia: destroy-eks.sh vs total-cleanup.sh

| Aspecto | destroy-eks.sh | total-cleanup.sh |
|---------|---|---|
| Terraform destroy | ✅ | ✅ |
| Borra ECR repos | ❌ | ✅ |
| Limpia imágenes huérfanas | ❌ | ✅ |
| Verifica cada recurso | ❌ | ✅ |
| Muestra tablas de verificación | ❌ | ✅ |
| Confirmación triple | 1x | 3x |
| Tiempo | 5 min | 10 min |
| Seguridad | Alta | Máxima |

**Recomendación:** Usa `total-cleanup.sh` para destrucción final garantizada

---

## 🔒 Seguridad de los Scripts

### Confirmaciones antes de destrucción:
```bash
# destroy-eks.sh pide:
✅ "¿Realmente deseas continuar? Escribe 'SÍ' para confirmar"

# total-cleanup.sh pide:
✅ "¿Estás COMPLETAMENTE seguro? (escribe 'DESTRUIR TODO')"
✅ "¿REALMENTE quieres destruir TODO? (escribe 'SÍ, DESTRUIR')"
✅ Espera 10 segundos adicionales
```

### Protección contra accidentes:
- No usan `-auto-approve` (excepto en total-cleanup)
- Piden confirmación explícita
- Muestran información del cluster
- Verifican recursos antes de eliminar

---

## 🐛 Troubleshooting de Scripts

### Error: "Command not found"
```bash
# Los scripts no son ejecutables
chmod +x /Users/pablo/Desktop/MLops/clase-5/scripts/*.sh

# Verifica
ls -l scripts/
```

### Error: "AWS credentials not found"
```bash
# Configura credenciales
aws configure

# Verifica
aws sts get-caller-identity
```

### Error: "terraform not found"
```bash
# Instala Terraform
brew install terraform

# Verifica
terraform version
```

### Error: "Permission denied"
```bash
# El script necesita permisos
chmod +x scripts/total-cleanup.sh
```

---

## 📝 Logs y Debugging

### Ver logs en tiempo real
```bash
# Durante setup-eks.sh
tail -f terraform-apply.log

# Ver logs de un pod
kubectl logs deployment/iris-api -f

# Ver eventos
kubectl get events -w
```

### Revisar estado de Terraform
```bash
cd infra

# Ver recursos creados
terraform state list

# Ver detalles de un recurso
terraform state show aws_eks_cluster.main

# Ver el plan antes de aplicar
terraform plan
```

---

## 💾 Archivos Generados

Después de ejecutar los scripts, se generan:

```
clase-5/
├─ infra/
│  ├─ .terraform/              (caché de Terraform)
│  ├─ terraform.tfstate        (estado actual)
│  ├─ terraform.tfstate.backup (backup)
│  └─ .terraform.lock.hcl      (lock file)
├─ .kube/config               (configuración de kubectl - HOME)
└─ scripts/
   └─ *.sh                     (todos los scripts)
```

---

## 🧹 Limpieza Manual Si Algo Falla

Si los scripts no funcionan, limpieza manual:

```bash
# 1. Destruir con Terraform
cd infra
terraform destroy -auto-approve
cd ..

# 2. Borrar ECR (manual)
REGION="us-east-1"

aws ecr delete-repository \
  --repository-name iris-api \
  --region $REGION \
  --force

aws ecr delete-repository \
  --repository-name workspace \
  --region $REGION \
  --force

# 3. Verificar en AWS Console
# https://console.aws.amazon.com/
```

---

## ✅ Verificación Final

Después de `total-cleanup.sh`, verifica:

```bash
# En la terminal
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`]' --output table
# Debería estar vacío

aws elbv2 describe-load-balancers --output table
# Debería estar vacío

aws ecr describe-repositories --output table
# Debería estar vacío

aws ec2 describe-volumes --query 'Volumes[?State==`available`]' --output table
# Debería estar vacío
```

```
En AWS Console:
- EC2 Dashboard → Instances: 0
- EC2 Dashboard → Load Balancers: 0
- EC2 Dashboard → Volumes: vacío
- EKS Dashboard → Clusters: 0
- ECR Dashboard → Repositories: vacío
```

---

## 🎓 Qué Aprendes Ejecutando Scripts

✅ Cómo provisionar infraestructura con Terraform  
✅ Cómo usar AWS CLI  
✅ Cómo desplegar en EKS  
✅ Cómo limpiar recursos  
✅ Cómo evitar costos inesperados  
✅ Cómo verificar que todo se borró  

---

## 📞 Soporte

Si un script falla:

1. Lee el mensaje de error completamente
2. Busca en `TROUBLESHOOTING_AWS.md`
3. Ejecuta `./scripts/check-prerequisites-aws.sh`
4. Verifica AWS Console
5. Pregunta al instructor

---

**¡Los scripts están listos para usar!** 🚀


