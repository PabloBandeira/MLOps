#!/bin/bash
#
# Script para servir modelo MLflow y probar con curl.
# Usa el último modelo registrado.

set -e

echo "=========================================="
echo "MLflow Model Serving"
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
    echo "Error: No se encontraron runs. Ejecuta primero: python src/train_mlflow.py"
    exit 1
fi

echo "Último Run ID: $LAST_RUN_ID"
echo ""

# Verificar que el modelo existe
MODEL_URI="runs:/$LAST_RUN_ID/model"
echo "Model URI: $MODEL_URI"
echo ""

# Instrucciones para servir
echo "Para servir el modelo, ejecutar en una terminal separada:"
echo ""
echo "  mlflow models serve -m $MODEL_URI -p 9000 --no-conda"
echo ""
echo "Luego, en otra terminal, probar con curl:"
echo ""
echo "  curl -X POST http://127.0.0.1:9000/invocations \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"dataframe_split\": {\"columns\": [\"0\", \"1\", \"2\", \"3\"], \"data\": [[5.1, 3.5, 1.4, 0.2]]}}'"
echo ""

# Preguntar si servir ahora
read -p "¿Deseas servir el modelo ahora? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Sirviendo modelo en http://127.0.0.1:9000"
    echo "Presiona Ctrl+C para detener"
    echo ""
    mlflow models serve -m "$MODEL_URI" -p 9000 --no-conda
else
    echo "Serving cancelado."
fi

