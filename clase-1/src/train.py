"""
Entrenamiento básico de modelo con scikit-learn.
Dataset: Iris
Semilla fija para reproducibilidad. ########
"""

from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score


def main():
    # Cargar dataset
    iris = load_iris()
    X, y = iris.data, iris.target

    # Split con semilla fija
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=39758307
    )

    # Entrenar modelo
    model = RandomForestClassifier(n_estimators=100, random_state=39758307)
    model.fit(X_train, y_train)

    # Predicción y métricas
    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="macro")

    print(f"acc: {acc:.4f}")
    print(f"f1_macro: {f1:.4f}")

    return acc, f1


if __name__ == "__main__":
    main()
