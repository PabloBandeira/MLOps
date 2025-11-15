# Script para ejecutar multiples experimentos con MLflow en PowerShell.
# Prueba diferentes hiperparametros y registra resultados.

$ErrorActionPreference = "Stop"

Write-Output "=========================================="
Write-Output "Ejecutando experimentos de MLflow"
Write-Output "=========================================="

# Experimento 1: Configuracion base
Write-Output ""
Write-Output "Experimento 1: n_estimators=50, max_depth=5"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=50, max_depth=5, random_state=42)"

# Experimento 2: Mas arboles
Write-Output ""
Write-Output "Experimento 2: n_estimators=100, max_depth=10"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=100, max_depth=10, random_state=42)"

# Experimento 3: Sin limite de profundidad
Write-Output ""
Write-Output "Experimento 3: n_estimators=150, max_depth=None"
python -c "from src.train_mlflow import train_model; train_model(n_estimators=150, max_depth=None, random_state=42)"

Write-Output ""
Write-Output "=========================================="
Write-Output "Experimentos completados"
Write-Output "Ver resultados en: mlflow ui --port 5000"
Write-Output "=========================================="
