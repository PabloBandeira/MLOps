#!/bin/bash

# ========================================
# Verificación de Prerrequisitos
# ========================================
# Este script verifica que todas las herramientas necesarias estén instaladas

echo "========================================="
echo "🔍 Verificación de Prerrequisitos"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OK="${GREEN}✓${NC}"
WARN="${YELLOW}⚠${NC}"
ERROR="${RED}✗${NC}"

all_ok=true

# Función para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "$OK $name está instalado"
        echo "   Versión: $version"
    else
        echo -e "$ERROR $name NO está instalado"
        echo "   💡 Instalación: $install_hint"
        all_ok=false
    fi
    echo ""
}

# Verificar Docker
echo "🐳 Docker"
if command -v docker &> /dev/null; then
    version=$(docker --version)
    echo -e "$OK Docker está instalado"
    echo "   $version"
    
    # Verificar que Docker daemon esté corriendo
    if docker ps &> /dev/null; then
        echo -e "$OK Docker daemon está corriendo"
    else
        echo -e "$ERROR Docker daemon NO está corriendo"
        echo "   💡 Inicia Docker Desktop"
        all_ok=false
    fi
else
    echo -e "$ERROR Docker NO está instalado"
    echo "   💡 Descarga Docker Desktop: https://www.docker.com/products/docker-desktop"
    all_ok=false
fi
echo ""

# Verificar Kind
echo "🎪 Kind (Kubernetes in Docker)"
check_command "kind" "Kind" "brew install kind  o  https://kind.sigs.k8s.io/docs/user/quick-start/"

# Verificar kubectl
echo "☸️  kubectl"
check_command "kubectl" "kubectl" "brew install kubectl  o  https://kubernetes.io/docs/tasks/tools/"

# Verificar Terraform
echo "🏗️  Terraform"
check_command "terraform" "Terraform" "brew install terraform  o  https://www.terraform.io/downloads"

# Verificar Python
echo "🐍 Python"
if command -v python3 &> /dev/null; then
    version=$(python3 --version)
    echo -e "$OK Python está instalado"
    echo "   $version"
    
    # Verificar versión mínima (3.9+)
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    if [[ $(echo "$python_version >= 3.9" | bc -l) -eq 1 ]]; then
        echo -e "$OK Versión adecuada (>= 3.9)"
    else
        echo -e "$WARN Versión antigua detectada. Se recomienda Python 3.9+"
    fi
else
    echo -e "$ERROR Python NO está instalado"
    echo "   💡 Instalación: brew install python@3.9"
    all_ok=false
fi
echo ""

# Verificar curl (generalmente viene instalado)
echo "🌐 curl"
check_command "curl" "curl" "brew install curl"

# Resumen
echo "========================================="
if $all_ok; then
    echo -e "${GREEN}✅ Todos los prerrequisitos están instalados${NC}"
    echo ""
    echo "🚀 Estás listo para ejecutar:"
    echo "   ./scripts/setup.sh"
else
    echo -e "${RED}❌ Faltan algunos prerrequisitos${NC}"
    echo ""
    echo "⚠️  Por favor instala las herramientas faltantes antes de continuar."
    echo ""
    echo "📚 Guía completa de instalación: ver ONBOARDING.md"
fi
echo "========================================="
echo ""

# Exit code
if $all_ok; then
    exit 0
else
    exit 1
fi

