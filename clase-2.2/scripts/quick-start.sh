#!/bin/bash
#
# Quick start script para clase-2.2
# Detecta el SO y ejecuta los comandos correctos

set -e

echo "=========================================="
echo "Clase 2.2 - Quick Start"
echo "=========================================="
echo ""

# Detectar SO
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    OS="macOS"
    
    # Detectar arquitectura
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        PLATFORM="--platform=linux/arm64/v8"
        echo "✅ Detectado: macOS Apple Silicon (arm64)"
    else
        PLATFORM=""
        echo "✅ Detectado: macOS Intel"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    OS="Windows"
    PLATFORM=""
    echo "✅ Detectado: Windows"
else
    # Linux
    OS="Linux"
    PLATFORM=""
    echo "✅ Detectado: Linux"
fi

echo ""
echo "=========================================="
echo "Paso 1: Construir imagen Docker"
echo "=========================================="
echo ""
echo "Ejecutando: docker build $PLATFORM -t demo-ml-clase22:local ."
echo ""

docker build $PLATFORM -t demo-ml-clase22:local .

echo ""
echo "✅ Imagen construida"
echo ""

# Verificar que se creó
if docker images | grep -q demo-ml-clase22; then
    echo "✅ Verificación: Imagen demo-ml-clase22:local existe"
else
    echo "❌ Error: No se pudo construir la imagen"
    exit 1
fi

echo ""
echo "=========================================="
echo "Paso 2: Ejecutar contenedor"
echo "=========================================="
echo ""
echo "Ejecutando: docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local"
echo ""
echo "🎯 Servicios:"
echo "  • MLflow UI: http://localhost:5000"
echo "  • Model Serving: http://localhost:9000"
echo ""
echo "⏹️  Para detener: Presiona Ctrl+C"
echo ""

docker run $PLATFORM -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local

