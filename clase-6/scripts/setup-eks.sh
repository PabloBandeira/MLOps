#!/bin/bash

################################################################################
# Script: setup-eks.sh
# Descripción: Provisiona y despliega todo en AWS EKS
# Uso: ./scripts/setup-eks.sh
################################################################################

set -e

echo "============================================================================"
echo "🚀 Iniciando setup de EKS"
echo "============================================================================"
echo ""

# Cambiar a directorio de infraestructura
cd "$(dirname "$0")/../infra"

echo "📝 Paso 1: Inicializar Terraform..."
terraform init

echo ""
echo "📊 Paso 2: Revisar plan de Terraform..."
echo "(Se mostrarán los recursos que se van a crear)"
terraform plan -out=tfplan

echo ""
read -p "¿Continuar con la creación? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "❌ Abortado por el usuario"
    exit 1
fi

echo ""
echo "🔨 Paso 3: Crear infraestructura (esto puede tomar 15-20 minutos)..."
terraform apply tfplan

echo ""
echo "✅ Infraestructura creada exitosamente!"
echo ""

# Obtener valores de output
CLUSTER_NAME=$(terraform output -raw cluster_id)
REGION=$(grep "aws_region = " terraform.tfvars | head -1 | cut -d'"' -f2)

echo "📋 Información de la infraestructura:"
echo "   Clúster: $CLUSTER_NAME"
echo "   Región: $REGION"
echo ""

echo "🔌 Paso 4: Configurando kubectl..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo ""
echo "⏳ Esperando a que los nodos estén listos..."
sleep 10

echo ""
echo "📌 Verificando nodos..."
kubectl get nodes

echo ""
echo "🎯 Paso 5: Información importante:"
echo ""
echo "ECR URLs (usa estas para subir imágenes):"
terraform output -raw ecr_iris_api_url
terraform output -raw ecr_workspace_url
echo ""

echo "🔑 Para subir imágenes a ECR:"
echo "   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin <ECR_URL>"
echo ""

echo "📝 Próximos pasos:"
echo "   1. Actualiza: infra/terraform.tfvars"
echo "      ecr_url = \"<ACCOUNT_ID>.dkr.ecr.$REGION.amazonaws.com\""
echo ""
echo "   2. Sube imágenes Docker:"
echo "      ./scripts/push-to-ecr.sh"
echo ""
echo "   3. Despliega servicios:"
echo "      cd infra && terraform apply"
echo ""
echo "   4. Obtén URLs de acceso:"
echo "      kubectl get svc"
echo ""
echo "⚠️  Recuerda destruir cuando termines:"
echo "   ./scripts/destroy-eks.sh"
echo ""
echo "============================================================================"

