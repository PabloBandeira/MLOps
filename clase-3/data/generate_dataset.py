"""
Script para generar dataset sintético para la Clase 3.
Genera datos de clasificación con 10 features numéricos.

Uso:
    python generate_dataset.py
    
Salida:
    dataset.csv - Dataset con 1000 muestras
"""

import pandas as pd
from sklearn.datasets import make_classification
import os


def generate_dataset(n_samples=1000, random_state=42):
    """
    Genera dataset sintético para problemas de clasificación binaria.

    Args:
        n_samples (int): Número de muestras a generar
        random_state (int): Seed para reproducibilidad

    Returns:
        pd.DataFrame: Dataset con features y target
    """
    print(f"Generando dataset con {n_samples} muestras...")

    # Generar datos de clasificación
    X, y = make_classification(
        n_samples=n_samples,
        n_features=10,
        n_informative=7,
        n_redundant=2,
        n_repeated=0,
        n_classes=2,
        weights=[0.6, 0.4],
        flip_y=0.05,
        random_state=random_state,
    )

    # Crear DataFrame con nombres descriptivos
    feature_names = [f"feature_{i}" for i in range(X.shape[1])]
    df = pd.DataFrame(X, columns=feature_names)
    df["target"] = y

    # Mostrar estadísticas
    print("\n✓ Dataset generado exitosamente")
    print(f"  - Shape: {df.shape}")
    print(f"  - Features: {len(feature_names)}")
    print("  - Distribución de clases:")
    print(f"    Clase 0: {(y == 0).sum()} ({100*(y == 0).sum()/len(y):.1f}%)")
    print(f"    Clase 1: {(y == 1).sum()} ({100*(y == 1).sum()/len(y):.1f}%)")
    print("\nPrimeras 5 filas:")
    print(df.head())

    return df


if __name__ == "__main__":
    # Generar dataset
    df = generate_dataset(n_samples=1000, random_state=42)

    # Guardar en CSV
    output_path = os.path.join(os.path.dirname(__file__), "dataset.csv")
    df.to_csv(output_path, index=False)
    print(f"\n✓ Dataset guardado en: {output_path}")
