"""
Tests para el módulo de entrenamiento.
"""

import sys
from pathlib import Path

# Agregar src/ al path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from train import main  # noqa: E402


def test_train_returns_valid_metrics():
    """Verifica que el entrenamiento devuelva métricas válidas."""
    acc, f1 = main()

    # Validar que las métricas estén en rango válido
    assert 0.0 <= acc <= 1.0, f"Accuracy fuera de rango: {acc}"
    assert 0.0 <= f1 <= 1.0, f"F1 score fuera de rango: {f1}"

    # Validar calidad mínima esperada (Iris es fácil)
    assert acc >= 0.85, f"Accuracy muy baja: {acc}"
    assert f1 >= 0.85, f"F1 score muy bajo: {f1}"


def test_train_reproducibility():
    """Verifica que el entrenamiento sea reproducible."""
    acc1, f1_1 = main()
    acc2, f1_2 = main()

    assert acc1 == acc2, "Accuracy no reproducible"
    assert f1_1 == f1_2, "F1 score no reproducible"
