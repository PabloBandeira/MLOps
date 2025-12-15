#!/bin/bash

# ========================================
# Script de Limpieza
# ========================================
# Este script elimina toda la infraestructura creada

set -e

echo "========================================="
echo "🧹 Limpieza de Infraestructura"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Confirmar
read -p "¿Estás seguro de que deseas eliminar toda la infraestructura? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""

# 1. Destruir recursos de Terraform
if [ -d "infra/.terraform" ]; then
    echo "🗑️  Destruyendo recursos de Terraform..."
    cd infra
    terraform destroy -auto-approve || warn "Error destruyendo recursos de Terraform"
    cd ..
    info "Recursos de Terraform destruidos"
else
    warn "No se encontraron recursos de Terraform"
fi

echo ""

# 2. Eliminar clúster Kind
if kind get clusters | grep -q "mlops-cluster"; then
    echo "🗑️  Eliminando clúster Kind..."
    kind delete cluster --name mlops-cluster
    info "Clúster eliminado"
else
    warn "No se encontró el clúster mlops-cluster"
fi

echo ""

# 3. Opcional: Eliminar imágenes Docker
read -p "¿Deseas eliminar también las imágenes Docker locales? (s/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "🗑️  Eliminando imágenes Docker..."
    docker rmi iris-api:latest 2>/dev/null || warn "No se pudo eliminar iris-api:latest"
    docker rmi workspace:latest 2>/dev/null || warn "No se pudo eliminar workspace:latest"
    info "Imágenes Docker eliminadas"
fi

echo ""
echo "========================================="
echo "✅ Limpieza completada"
echo "========================================="
echo ""
echo "Para volver a desplegar, ejecuta:"
echo "  ./scripts/setup.sh"
echo ""

