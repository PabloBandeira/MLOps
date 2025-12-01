"""
Script de entrenamiento del modelo Iris.
Este script se ejecuta durante el BUILD de la imagen Docker.
El modelo resultante queda "cocinado" dentro del contenedor.
"""

import joblib
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import os


def train_model():
    """
    Entrena un modelo RandomForest con el dataset Iris.
    Guarda el modelo como model.joblib.
    """
    print("=" * 60)
    print("🚀 INICIANDO ENTRENAMIENTO DEL MODELO IRIS")
    print("=" * 60)

    # Cargar dataset
    print("\n📊 Cargando dataset Iris...")
    iris = load_iris()
    X = pd.DataFrame(iris.data, columns=iris.feature_names)
    y = pd.Series(iris.target, name="target")

    print(f"   ✅ Dataset cargado: {X.shape[0]} muestras, {X.shape[1]} features")
    print(f"   ✅ Clases: {iris.target_names.tolist()}")

    # Split
    print("\n🔀 Dividiendo dataset (80% train, 20% test)...")
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    print(f"   ✅ Train: {X_train.shape[0]} muestras")
    print(f"   ✅ Test: {X_test.shape[0]} muestras")

    # Entrenar modelo
    print("\n🤖 Entrenando RandomForestClassifier...")
    model = RandomForestClassifier(
        n_estimators=100, max_depth=5, random_state=42, n_jobs=-1
    )
    model.fit(X_train, y_train)
    print("   ✅ Entrenamiento completado")

    # Evaluar
    print("\n📈 Evaluando modelo...")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    print(f"   ✅ Accuracy: {accuracy:.4f}")
    print("\n📋 Classification Report:")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))

    # Guardar modelo
    model_path = "/app/model.joblib"
    os.makedirs(os.path.dirname(model_path), exist_ok=True)

    print(f"\n💾 Guardando modelo en {model_path}...")

    # Guardar modelo con metadata
    model_artifact = {
        "model": model,
        "feature_names": iris.feature_names,
        "target_names": iris.target_names.tolist(),
        "accuracy": accuracy,
        "version": "1.0.0",
    }

    joblib.dump(model_artifact, model_path)

    # Verificar que se guardó correctamente
    if os.path.exists(model_path):
        file_size = os.path.getsize(model_path) / 1024  # KB
        print(f"   ✅ Modelo guardado correctamente ({file_size:.2f} KB)")
    else:
        raise FileNotFoundError(f"Error: No se pudo guardar el modelo en {model_path}")

    print("\n" + "=" * 60)
    print("✨ ENTRENAMIENTO COMPLETADO EXITOSAMENTE")
    print("=" * 60)
    print("\n📦 Modelo listo para ser empaquetado en la imagen Docker")
    print(f"🎯 Accuracy: {accuracy:.4f}")
    print("🔖 Versión: 1.0.0\n")

    return model_artifact


if __name__ == "__main__":
    train_model()
