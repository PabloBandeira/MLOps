#!/bin/bash
#
# Script para ejecutar multiples experimentos con MLflow.
# Prueba diferentes hiperparametros y registra resultados.

set -e

echo "=========================================="
echo "Ejecutando experimentos de MLflow"
echo "=========================================="

# Experimento 1: Configuracion base
echo ""
echo "Experimento 1: n_estimators=50, max_depth=5"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=50, max_depth=5, random_state=27087419)"

# Experimento 2: Mas arboles
echo ""
echo "Experimento 2: n_estimators=100, max_depth=10"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=100, max_depth=10, random_state=27087419)"

# Experimento 3: Sin limite de profundidad
echo ""
echo "Experimento 3: n_estimators=150, max_depth=None"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=150, max_depth=None, random_state=27087419)"

echo ""
echo "=========================================="
echo "Experimentos completados"
echo "Ver resultados en: mlflow ui --port 5000"
echo "=========================================="

