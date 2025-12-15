#!/bin/bash

################################################################################
# Script: push-to-ecr.sh
# Descripción: Construye y sube imágenes a ECR
# Uso: ./scripts/push-to-ecr.sh
################################################################################

set -e

echo "============================================================================"
echo "🐳 Construyendo y subiendo imágenes a ECR"
echo "============================================================================"
echo ""

# Obtener información
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "📊 Información:"
echo "   Account ID: $ACCOUNT_ID"
echo "   Región: $REGION"
echo "   ECR URL: $ECR_URL"
echo ""

# Login a ECR
echo "🔑 Haciendo login a ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo ""
echo "🔨 Construyendo imágenes..."
echo ""

# Iris API
echo "📦 Iris API..."
cd ../app_iris
docker build -t iris-api:latest .
docker tag iris-api:latest $ECR_URL/iris-api:latest
echo "   ✅ Imagen construida"

echo ""
echo "📤 Subiendo iris-api a ECR..."
docker push $ECR_URL/iris-api:latest
echo "   ✅ Imagen subida"

echo ""

# Workspace
echo "📦 Workspace..."
cd ../app_workspace
docker build -t workspace:latest .
docker tag workspace:latest $ECR_URL/workspace:latest
echo "   ✅ Imagen construida"

echo ""
echo "📤 Subiendo workspace a ECR..."
docker push $ECR_URL/workspace:latest
echo "   ✅ Imagen subida"

echo ""
echo "============================================================================"
echo ""
echo "✅ Imágenes subidas exitosamente!"
echo ""
echo "📝 Ahora debes:"
echo "   1. Actualizar infra/terraform.tfvars:"
echo "      ecr_url = \"$ECR_URL\""
echo ""
echo "   2. Desplegar servicios:"
echo "      cd infra && terraform apply"
echo ""
echo "============================================================================"

