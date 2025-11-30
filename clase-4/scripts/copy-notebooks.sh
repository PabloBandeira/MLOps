#!/bin/bash

# ========================================
# Script para copiar notebooks al workspace
# ========================================
# Uso: ./scripts/copy-notebooks.sh

set -e

echo "📓 Copiando notebooks al workspace..."
echo ""

# Obtener el nombre del pod de workspace
WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')

if [ -z "$WORKSPACE_POD" ]; then
    echo "❌ No se encontró el pod de workspace"
    echo "   Verifica que el clúster esté corriendo con: kubectl get pods"
    exit 1
fi

echo "✓ Pod encontrado: $WORKSPACE_POD"
echo ""

# Crear directorio si no existe
echo "📁 Creando directorio /app/notebooks en el pod..."
kubectl exec "$WORKSPACE_POD" -- mkdir -p /app/notebooks 2>/dev/null || true

# Copiar todos los notebooks
echo "📋 Copiando notebooks..."
for notebook in notebooks/*.ipynb; do
    if [ -f "$notebook" ]; then
        filename=$(basename "$notebook")
        echo "   → Copiando $filename..."
        kubectl cp "$notebook" "$WORKSPACE_POD:/app/notebooks/$filename"
    fi
done

echo ""
echo "✅ Notebooks copiados exitosamente"
echo ""
echo "💡 Refresca JupyterLab (http://localhost:30003) para ver los notebooks"

