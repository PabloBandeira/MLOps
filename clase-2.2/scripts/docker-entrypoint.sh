#!/bin/bash
#
# Script de entrada para el contenedor Docker
# Ejecuta: entrenamientos, MLflow UI y Model Serving
# Orquesta todo dentro del contenedor

set -e

echo "=========================================="
echo "Iniciando Clase 2.2 - Full Docker Setup"
echo "=========================================="
echo ""

# ============================================
# 1. ENTRENAR MODELO
# ============================================
echo "📊 Paso 1: Ejecutando experimentos..."
echo "=========================================="
bash scripts/train-in-docker.sh

echo ""
echo "✅ Entrenamientos completados"
echo ""

# ============================================
# 2. INICIAR MLFLOW UI EN BACKGROUND
# ============================================
echo "🎯 Paso 2: Levantando MLflow UI en puerto 5000..."
echo "=========================================="
mlflow ui --host 0.0.0.0 --port 5000 &
MLFLOW_UI_PID=$!
echo "✅ MLflow UI iniciado (PID: $MLFLOW_UI_PID)"
sleep 2

echo ""

# ============================================
# 3. OBTENER ÚLTIMO RUN ID Y SERVIR MODELO
# ============================================
echo "🚀 Paso 3: Levantando Model Serving en puerto 9000..."
echo "=========================================="

# Obtener el último run ID
LAST_RUN_ID=$(python -c "
import mlflow
client = mlflow.tracking.MlflowClient()
experiment = client.get_experiment_by_name('iris-classification')
if experiment:
    runs = client.search_runs(experiment.experiment_id, order_by=['start_time DESC'], max_results=1)
    if runs:
        print(runs[0].info.run_id)
    else:
        print('NO_RUNS')
else:
    print('NO_EXPERIMENT')
")

if [ "$LAST_RUN_ID" = "NO_RUNS" ] || [ "$LAST_RUN_ID" = "NO_EXPERIMENT" ]; then
    echo "❌ Error: No se encontraron runs"
    exit 1
fi

echo "✅ Último Run ID: $LAST_RUN_ID"
echo ""

# Servir modelo
MODEL_URI="runs:/$LAST_RUN_ID/model"
echo "🔗 Model URI: $MODEL_URI"
echo ""
echo "=========================================="
echo "✅ SERVICIOS INICIADOS"
echo "=========================================="
echo ""
echo "📋 Acceso a servicios:"
echo "  • MLflow UI: http://localhost:5000"
echo "  • Model Serving: http://localhost:9000"
echo ""
echo "📝 Ejemplo de predicción (en otra terminal):"
echo "  curl -X POST http://localhost:9000/invocations \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"dataframe_split\": {\"columns\": [\"0\", \"1\", \"2\", \"3\"], \"data\": [[7.7, 3.8, 6.7, 2.2]]}}'"
echo ""
echo "⏹️  Para detener los servicios, presiona Ctrl+C"
echo "=========================================="
echo ""

# Servir modelo en foreground (esto mantiene el contenedor vivo)
mlflow models serve -m "$MODEL_URI" -p 9000 --no-conda --host 0.0.0.0

