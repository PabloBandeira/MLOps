"""
Tests para el módulo de entrenamiento con MLflow.
"""

import sys
from pathlib import Path

# Agregar src/ al path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from train_mlflow import train_model  # noqa: E402


def test_train_mlflow_returns_valid_metrics():
    """Verifica que el entrenamiento con MLflow devuelva métricas válidas."""
    acc, f1 = train_model(n_estimators=50, max_depth=5, random_state=42)

    # Validar que las métricas estén en rango válido
    assert 0.0 <= acc <= 1.0, f"Accuracy fuera de rango: {acc}"
    assert 0.0 <= f1 <= 1.0, f"F1 score fuera de rango: {f1}"

    # Validar calidad mínima esperada
    assert acc >= 0.85, f"Accuracy muy baja: {acc}"
    assert f1 >= 0.85, f"F1 score muy bajo: {f1}"


def test_train_mlflow_reproducibility():
    """Verifica que el entrenamiento con MLflow sea reproducible."""
    acc1, f1_1 = train_model(n_estimators=50, max_depth=5, random_state=42)
    acc2, f1_2 = train_model(n_estimators=50, max_depth=5, random_state=42)

    assert acc1 == acc2, "Accuracy no reproducible"
    assert f1_1 == f1_2, "F1 score no reproducible"


def test_train_mlflow_different_params():
    """Verifica que diferentes parámetros produzcan resultados."""
    acc1, _ = train_model(n_estimators=50, max_depth=5, random_state=42)
    acc2, _ = train_model(n_estimators=100, max_depth=10, random_state=42)

    # Ambos deben ser válidos
    assert 0.0 <= acc1 <= 1.0
    assert 0.0 <= acc2 <= 1.0
