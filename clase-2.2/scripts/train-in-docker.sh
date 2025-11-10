#!/bin/bash
#
# Script para ejecutar múltiples experimentos con MLflow dentro de Docker
# Prueba diferentes hiperparámetros y registra resultados

set -e

echo "Ejecutando experimentos de MLflow en Docker..."
echo ""

# Experimento 1: Configuración base
echo "Experimento 1: n_estimators=50, max_depth=5"
python -c "
from src.train_mlflow import train_model
train_model(n_estimators=50, max_depth=5, random_state=42)
"
echo ""

# Experimento 2: Más árboles
echo "Experimento 2: n_estimators=100, max_depth=10"
python -c "
from src.train_mlflow import train_model
train_model(n_estimators=100, max_depth=10, random_state=42)
"
echo ""

# Experimento 3: Sin límite de profundidad
echo "Experimento 3: n_estimators=150, max_depth=None"
python -c "
from src.train_mlflow import train_model
train_model(n_estimators=150, max_depth=None, random_state=42)
"

echo ""
echo "✓ Experimentos completados"

