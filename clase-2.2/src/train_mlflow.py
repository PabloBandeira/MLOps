"""
Entrenamiento con MLflow tracking.
Dataset: Iris
Logging de parámetros, métricas y modelo.
"""

import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score


def train_model(n_estimators=100, max_depth=None, random_state=42):
    """
    Entrena modelo con tracking de MLflow.

    Args:
        n_estimators: Número de árboles
        max_depth: Profundidad máxima de árboles
        random_state: Semilla para reproducibilidad

    Returns:
        Tupla (accuracy, f1_score)
    """
    # Configurar experiment
    mlflow.set_experiment("iris-classification")

    with mlflow.start_run():
        # Log parámetros
        mlflow.log_param("n_estimators", n_estimators)
        mlflow.log_param("max_depth", max_depth)
        mlflow.log_param("random_state", random_state)
        mlflow.log_param("dataset", "iris")

        # Cargar dataset
        iris = load_iris()
        X, y = iris.data, iris.target

        # Split con semilla fija
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=random_state
        )

        # Entrenar modelo
        model = RandomForestClassifier(
            n_estimators=n_estimators, max_depth=max_depth, random_state=random_state
        )
        model.fit(X_train, y_train)

        # Predicción
        y_pred = model.predict(X_test)

        # Calcular métricas
        acc = accuracy_score(y_test, y_pred)
        f1 = f1_score(y_test, y_pred, average="macro")
        precision = precision_score(y_test, y_pred, average="macro")
        recall = recall_score(y_test, y_pred, average="macro")

        # Log métricas
        mlflow.log_metric("accuracy", acc)
        mlflow.log_metric("f1_macro", f1)
        mlflow.log_metric("precision_macro", precision)
        mlflow.log_metric("recall_macro", recall)

        # Log modelo
        mlflow.sklearn.log_model(
            model, "model", registered_model_name="iris-rf-classifier"
        )

        # Print resultados
        print(f"Run ID: {mlflow.active_run().info.run_id}")
        print(f"acc: {acc:.4f}")
        print(f"f1_macro: {f1:.4f}")
        print(f"precision_macro: {precision:.4f}")
        print(f"recall_macro: {recall:.4f}")

        return acc, f1


if __name__ == "__main__":
    # Entrenamiento por defecto
    train_model()
