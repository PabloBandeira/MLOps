#!/bin/bash

# ========================================
# Script de Setup Completo
# ========================================
# Este script automatiza todo el proceso de despliegue

set -e  # Exit on error

echo "========================================="
echo "🚀 CLASE 4: Setup de MLOps en Kubernetes"
echo "========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mensajes
info() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# 1. Verificar prerrequisitos
echo "📋 Verificando prerrequisitos..."
echo ""

if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Por favor instala Docker Desktop."
fi
info "Docker encontrado"

if ! command -v kind &> /dev/null; then
    error "Kind no está instalado. Por favor instala Kind."
fi
info "Kind encontrado"

if ! command -v kubectl &> /dev/null; then
    error "kubectl no está instalado. Por favor instala kubectl."
fi
info "kubectl encontrado"

if ! command -v terraform &> /dev/null; then
    error "Terraform no está instalado. Por favor instala Terraform."
fi
info "Terraform encontrado"

echo ""
echo "✅ Todos los prerrequisitos están instalados"
echo ""

# 2. Construir imágenes Docker
echo "========================================="
echo "🔨 Construyendo imágenes Docker..."
echo "========================================="
echo ""

echo "📦 Construyendo Iris API (con modelo entrenado)..."
cd app_iris
docker build -t iris-api:latest . || error "Error construyendo Iris API"
cd ..
info "Iris API construida"
echo ""

echo "📦 Construyendo Workspace Jupyter..."
cd app_workspace
docker build -t workspace:latest . || error "Error construyendo Workspace"
cd ..
info "Workspace construido"
echo ""

# 3. Verificar si el clúster ya existe
echo "========================================="
echo "🏗️  Configurando clúster Kind..."
echo "========================================="
echo ""

if kind get clusters | grep -q "mlops-cluster"; then
    warn "El clúster 'mlops-cluster' ya existe"
    read -p "¿Deseas eliminarlo y crear uno nuevo? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo "🗑️  Eliminando clúster existente..."
        kind delete cluster --name mlops-cluster
        info "Clúster eliminado"
    else
        info "Usando clúster existente"
    fi
fi

# Crear clúster si no existe
if ! kind get clusters | grep -q "mlops-cluster"; then
    echo "🏗️  Creando clúster Kind..."
    kind create cluster --name mlops-cluster --config infra/kind-config.yaml || error "Error creando clúster"
    info "Clúster creado"
    
    # Esperar a que el clúster esté listo
    echo "⏳ Esperando a que el clúster esté listo..."
    sleep 5
fi
echo ""

# 4. Cargar imágenes al clúster
echo "========================================="
echo "📥 Cargando imágenes al clúster Kind..."
echo "========================================="
echo ""

echo "📤 Cargando iris-api:latest..."
kind load docker-image iris-api:latest --name mlops-cluster || error "Error cargando Iris API"
info "Iris API cargada"

echo "📤 Cargando workspace:latest..."
kind load docker-image workspace:latest --name mlops-cluster || error "Error cargando Workspace"
info "Workspace cargado"
echo ""

# 5. Desplegar con Terraform
echo "========================================="
echo "🚀 Desplegando infraestructura con Terraform..."
echo "========================================="
echo ""

cd infra

# Inicializar Terraform (si es necesario)
if [ ! -d ".terraform" ]; then
    echo "🔧 Inicializando Terraform..."
    terraform init || error "Error inicializando Terraform"
    info "Terraform inicializado"
    echo ""
fi

# Aplicar configuración
echo "📝 Aplicando configuración de Terraform..."
terraform apply -auto-approve || error "Error aplicando Terraform"
info "Infraestructura desplegada"
echo ""

cd ..

# 6. Esperar a que los pods estén listos
echo "========================================="
echo "⏳ Esperando a que los pods estén listos..."
echo "========================================="
echo ""

echo "Esto puede tomar 1-2 minutos..."
echo ""

# Esperar a que todos los pods estén Running
timeout=300  # 5 minutos
elapsed=0
interval=5

while [ $elapsed -lt $timeout ]; do
    not_ready=$(kubectl get pods --no-headers 2>/dev/null | grep -v "Running\|Completed" | wc -l)
    
    if [ "$not_ready" -eq 0 ]; then
        info "Todos los pods están listos"
        break
    fi
    
    echo "⏳ Esperando... ($elapsed segundos) - $not_ready pods pendientes"
    sleep $interval
    elapsed=$((elapsed + interval))
done

if [ $elapsed -ge $timeout ]; then
    error "Timeout esperando a que los pods estén listos"
fi

echo ""

# 7. Mostrar estado
echo "========================================="
echo "📊 Estado del Clúster"
echo "========================================="
echo ""

echo "🎯 Pods:"
kubectl get pods
echo ""

echo "🌐 Servicios:"
kubectl get services
echo ""

# 8. Copiar notebooks al workspace (opcional)
echo "========================================="
echo "📓 Configurando notebooks..."
echo "========================================="
echo ""

WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')

if [ -n "$WORKSPACE_POD" ]; then
    echo "📋 Copiando notebooks al workspace..."
    # Crear directorio si no existe
    kubectl exec "$WORKSPACE_POD" -- mkdir -p /app/notebooks 2>/dev/null || true
    # Copiar el notebook
    kubectl cp notebooks/01_simulacion.ipynb "$WORKSPACE_POD:/app/notebooks/01_simulacion.ipynb" 2>/dev/null && \
        info "Notebook copiado exitosamente" || \
        warn "No se pudo copiar el notebook (verifica que el archivo exista)"
else
    warn "No se encontró el pod de workspace"
fi

echo ""

# 9. Mostrar información de acceso
echo "========================================="
echo "✅ ¡DESPLIEGUE COMPLETADO!"
echo "========================================="
echo ""

echo "🌐 URLs de Acceso:"
echo "  MLflow:       http://localhost:30001"
echo "  Evidently:    http://localhost:30002"
echo "  Jupyter Lab:  http://localhost:30003"
echo "  Iris API:     http://localhost:30004"
echo ""

echo "📚 Próximos Pasos:"
echo "  1. Abre Jupyter Lab en tu navegador: http://localhost:30003"
echo "  2. Navega a notebooks/01_simulacion.ipynb"
echo "  3. Ejecuta todas las celdas"
echo "  4. Revisa los resultados en MLflow y Evidently"
echo ""

echo "🔧 Comandos Útiles:"
echo "  kubectl get pods              # Ver pods"
echo "  kubectl get services          # Ver servicios"
echo "  kubectl logs -l app=iris-api  # Ver logs del Iris API"
echo "  kubectl scale deployment iris-api --replicas=5  # Escalar"
echo ""

echo "🧹 Para limpiar:"
echo "  cd infra && terraform destroy  # Destruir recursos"
echo "  kind delete cluster --name mlops-cluster  # Eliminar clúster"
echo ""

echo "========================================="
echo "🎉 ¡Éxito! Todo está listo para usar."
echo "========================================="

