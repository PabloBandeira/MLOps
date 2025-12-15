#!/bin/bash

################################################################################
# Script: check-prerequisites-aws.sh
# Descripción: Verifica que todas las herramientas necesarias están instaladas
# Uso: ./scripts/check-prerequisites-aws.sh
################################################################################

set -e

echo "============================================================================"
echo "🔍 Verificando prerequisitos para AWS EKS"
echo "============================================================================"
echo ""

MISSING_TOOLS=0

# Función para verificar comandos
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n1)
        echo "✅ $name instalado: $version"
    else
        echo "❌ $name NO instalado"
        if [ ! -z "$install_hint" ]; then
            echo "   Instalar: $install_hint"
        fi
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    fi
}

echo "📦 Verificando herramientas requeridas:"
echo ""

check_command "aws" "AWS CLI" "brew install awscliv2"
check_command "eksctl" "eksctl" "brew tap weaveworks/tap && brew install weaveworks/tap/eksctl"
check_command "kubectl" "kubectl" "brew install kubectl"
check_command "terraform" "Terraform" "brew install terraform"
check_command "docker" "Docker" "https://www.docker.com/products/docker-desktop"

echo ""
echo "============================================================================"

# Verificar credenciales de AWS
echo ""
echo "🔐 Verificando credenciales de AWS:"
echo ""

if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
        echo "✅ Credenciales de AWS válidas"
        echo "   Account ID: $ACCOUNT_ID"
        echo "   ARN: $USER_ARN"
    else
        echo "❌ Credenciales de AWS no configuradas"
        echo "   Ejecuta: aws configure"
        MISSING_TOOLS=$((MISSING_TOOLS + 1))
    fi
else
    echo "⚠️  AWS CLI no está instalado, saltando validación"
fi

echo ""
echo "============================================================================"
echo ""

if [ $MISSING_TOOLS -eq 0 ]; then
    echo "✅ ¡Todos los prerequisitos están instalados!"
    echo ""
    echo "🚀 Próximos pasos:"
    echo "   1. Edita: infra/terraform.tfvars"
    echo "   2. Ejecuta: ./scripts/setup-eks.sh"
    exit 0
else
    echo "❌ Faltan $MISSING_TOOLS herramienta(s)"
    echo ""
    echo "📖 Consulta la guía de instalación:"
    echo "   GUIA_MIGRACION_COMPLETA.md"
    exit 1
fi

