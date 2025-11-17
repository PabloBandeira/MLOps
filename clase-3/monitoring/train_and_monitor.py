"""
Script Principal: Entrenamiento y Monitoreo de Modelos con MLflow + Evidently

Este script implementa el workflow completo de Clase 3:
  1. Carga y preparación de datos
  2. Entrenamiento del modelo
  3. Tracking con MLflow
  4. Generación de reportes con Evidently
  5. Envío de datos a Evidently Service
  6. Extracción y logging de métricas

Uso:
    docker-compose exec monitoring python train_and_monitor.py
    
Salida:
    - Modelo registrado en MLflow
    - Reportes HTML en /app/reports/
    - Métricas en MLflow UI
    - Dashboards en Evidently Service
"""

import os
import logging
import warnings
import numpy as np
import pandas as pd
import requests
from datetime import datetime

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import load_iris
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
)

import mlflow
import mlflow.sklearn
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset, ClassificationPreset

warnings.filterwarnings("ignore")

# =============================
# CONFIGURACIÓN DE LOGGING
# =============================
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# =============================
# CONFIGURACIÓN DE VARIABLES
# =============================
REPORTS_PATH = "/app/reports"
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
EVIDENTLY_SERVICE_URL = os.getenv("EVIDENTLY_SERVICE_URL", "http://localhost:8000")

# Crear directorio de reportes si no existe
os.makedirs(REPORTS_PATH, exist_ok=True)


# =============================
# PASO 1: CARGA Y PREPARACIÓN DE DATOS (IRIS)
# =============================
def load_and_prepare_data():
    """
    Carga el dataset Iris y realiza preparación básica.

    Returns:
        tuple: (X, y, feature_names, df)
    """
    logger.info("=" * 60)
    logger.info("PASO 1: CARGA Y PREPARACIÓN DE DATOS (IRIS)")
    logger.info("=" * 60)

    try:
        # Cargar Iris
        iris = load_iris()
        X = iris.data
        y = iris.target
        feature_names = list(iris.feature_names)
        target_names = list(iris.target_names)

        # Crear DataFrame para mejor visualización
        df = pd.DataFrame(X, columns=feature_names)
        df["target"] = y

        logger.info("✓ Dataset Iris cargado")
        logger.info(f"  - Shape: {df.shape}")
        logger.info(f"  - Columnas: {list(df.columns)}")
        logger.info("  - Tipos de dato:")
        for col, dtype in df.dtypes.items():
            logger.info(f"    * {col}: {dtype}")

        # Análisis de clases
        unique, counts = np.unique(y, return_counts=True)
        logger.info("\n✓ Distribución de clases:")
        for cls, count in zip(unique, counts):
            class_name = target_names[int(cls)]
            logger.info(
                f"  - Clase {int(cls)} ({class_name}): {count} muestras ({100*count/len(y):.1f}%)"
            )

        logger.info("✓ Sin valores faltantes")

        logger.info(f"\n✓ Features: {len(feature_names)}")
        logger.info(f"  - {', '.join(feature_names)}\n")

        return X, y, feature_names, df

    except Exception as e:
        logger.error(f"✗ Error cargando datos: {str(e)}")
        raise


# =============================
# PASO 2: TRAIN/TEST SPLIT
# =============================
def split_data(X, y, test_size=0.2, random_state=39758307):
    """
    Divide datos en train y test de forma estratificada.

    Args:
        X (np.array): Features
        y (np.array): Target
        test_size (float): Porcentaje para test
        random_state (int): Seed para reproducibilidad

    Returns:
        tuple: (X_train, X_test, y_train, y_test)
    """
    logger.info("=" * 60)
    logger.info("PASO 2: TRAIN/TEST SPLIT ESTRATIFICADO")
    logger.info("=" * 60)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, stratify=y, random_state=random_state
    )

    logger.info(f"✓ Train set: {X_train.shape[0]} muestras ({100*(1-test_size):.0f}%)")
    logger.info(f"✓ Test set:  {X_test.shape[0]} muestras ({100*test_size:.0f}%)\n")

    return X_train, X_test, y_train, y_test


# =============================
# PASO 3: ENTRENAMIENTO DEL MODELO
# =============================
def train_model(X_train, y_train, hyperparams=None):
    """
    Entrena un modelo Random Forest con validación cruzada.

    Args:
        X_train (np.array): Features de entrenamiento
        y_train (np.array): Target de entrenamiento
        hyperparams (dict): Hiperparámetros del modelo

    Returns:
        tuple: (model, cv_scores)
    """
    logger.info("=" * 60)
    logger.info("PASO 3: ENTRENAMIENTO DEL MODELO")
    logger.info("=" * 60)

    if hyperparams is None:
        hyperparams = {
            "n_estimators": 100,
            "max_depth": 10,
            "min_samples_split": 5,
            "min_samples_leaf": 2,
            "random_state": 39758307,
            "n_jobs": -1,
        }

    logger.info("✓ Hiperparámetros:")
    for param, value in hyperparams.items():
        logger.info(f"  - {param}: {value}")

    # Entrenar modelo
    model = RandomForestClassifier(**hyperparams)
    model.fit(X_train, y_train)
    logger.info("✓ Modelo entrenado exitosamente")

    # Validación cruzada
    cv_scores = cross_val_score(model, X_train, y_train, cv=5, scoring="f1_weighted")
    logger.info("\n✓ Validación cruzada (5-fold):")
    logger.info(f"  - F1 scores: {cv_scores}")
    logger.info(f"  - Media: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})\n")

    return model, cv_scores


# =============================
# PASO 4: EVALUACIÓN DEL MODELO
# =============================
def evaluate_model(model, X_test, y_test, feature_names):
    """
    Calcula métricas de evaluación del modelo.

    Args:
        model: Modelo entrenado
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        feature_names (list): Nombres de features

    Returns:
        dict: Diccionario con métricas
    """
    logger.info("=" * 60)
    logger.info("PASO 4: EVALUACIÓN DEL MODELO")
    logger.info("=" * 60)

    # Predicciones
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)  # Mantener todas las probabilidades

    # Métricas (weighted para multiclass)
    metrics = {
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(
            y_test, y_pred, average="weighted", zero_division=0
        ),
        "recall": recall_score(y_test, y_pred, average="weighted", zero_division=0),
        "f1": f1_score(y_test, y_pred, average="weighted", zero_division=0),
        "roc_auc": roc_auc_score(y_test, y_pred_proba, multi_class="ovr"),
    }

    logger.info("✓ Métricas de evaluación:")
    for metric, value in metrics.items():
        logger.info(f"  - {metric}: {value:.4f}")

    # Feature importance
    feature_importance = pd.DataFrame(
        {"feature": feature_names, "importance": model.feature_importances_}
    ).sort_values("importance", ascending=False)

    logger.info("\n✓ Feature importance (Top 5):")
    for idx, row in feature_importance.head().iterrows():
        logger.info(f"  - {row['feature']}: {row['importance']:.4f}")

    logger.info("")

    return metrics, y_pred, y_pred_proba


# =============================
# PASO 5: CONFIGURAR MLflow TRACKING
# =============================
def setup_mlflow(experiment_name="Model Monitoring - Clase 3"):
    """
    Configura MLflow y crea experimento.

    Args:
        experiment_name (str): Nombre del experimento

    Returns:
        str: Experimento ID
    """
    logger.info("=" * 60)
    logger.info("PASO 5: CONFIGURAR MLflow TRACKING")
    logger.info("=" * 60)

    # Conectar a MLflow
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    logger.info(f"✓ MLflow tracking URI: {MLFLOW_TRACKING_URI}")

    # Crear experimento
    try:
        experiment_id = mlflow.create_experiment(experiment_name)
        logger.info(f"✓ Nuevo experimento creado: {experiment_name}")
    except Exception:
        experiment = mlflow.get_experiment_by_name(experiment_name)
        experiment_id = experiment.experiment_id
        logger.info(f"✓ Usando experimento existente: {experiment_name}")

    logger.info(f"✓ Experiment ID: {experiment_id}\n")

    return experiment_id


# =============================
# PASO 6: LOGGING EN MLflow
# =============================
def log_to_mlflow(
    experiment_id, model, hyperparams, metrics, cv_scores, X_test, y_test, y_pred
):
    """
    Registra modelo, parámetros y métricas en MLflow.

    Args:
        experiment_id (str): ID del experimento
        model: Modelo entrenado
        hyperparams (dict): Hiperparámetros
        metrics (dict): Métricas de evaluación
        cv_scores (np.array): Scores de validación cruzada
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        y_pred (np.array): Predicciones

    Returns:
        str: Run ID
    """
    logger.info("=" * 60)
    logger.info("PASO 6: LOGGING EN MLflow")
    logger.info("=" * 60)

    # Iniciar run
    with mlflow.start_run(experiment_id=experiment_id):
        # Log parámetros
        mlflow.log_params(hyperparams)
        logger.info(f"✓ Parámetros registrados: {len(hyperparams)}")

        # Log métricas
        mlflow.log_metrics(metrics)
        logger.info(f"✓ Métricas registradas: {len(metrics)}")

        # Log CV scores
        for i, score in enumerate(cv_scores):
            mlflow.log_metric(f"cv_fold_{i+1}_f1", score)
        mlflow.log_metric("cv_mean_f1", cv_scores.mean())
        mlflow.log_metric("cv_std_f1", cv_scores.std())
        logger.info(f"✓ CV scores registrados: {len(cv_scores)} folds")

        # Log modelo
        mlflow.sklearn.log_model(model, "model")
        logger.info("✓ Modelo registrado")

        # Obtener run ID
        run_id = mlflow.active_run().info.run_id
        logger.info(f"✓ Run ID: {run_id}\n")

        return run_id


# =============================
# PASO 7: GENERAR REPORTES EVIDENTLY
# =============================
def generate_evidently_reports(
    model, X_train, X_test, y_train, y_test, y_pred, feature_names, run_id
):
    """
    Genera reportes HTML con Evidently AI.

    Args:
        model: Modelo entrenado
        X_train, X_test (np.array): Features
        y_train, y_test (np.array): Targets
        y_pred (np.array): Predicciones
        feature_names (list): Nombres de features
        run_id (str): ID del run en MLflow

    Returns:
        dict: Rutas de reportes generados
    """
    logger.info("=" * 60)
    logger.info("PASO 7: GENERAR REPORTES EVIDENTLY")
    logger.info("=" * 60)

    reports_paths = {}

    try:
        # Preparar datos con predicciones (ambos DataFrames con mismas columnas)
        train_df = pd.DataFrame(X_train, columns=feature_names)
        train_df["target"] = y_train
        train_df["prediction"] = model.predict(X_train)

        test_df = pd.DataFrame(X_test, columns=feature_names)
        test_df["target"] = y_test
        test_df["prediction"] = y_pred

        # --------- Reporte 1: Classification Performance ---------
        logger.info("\n✓ Generando reporte de clasificación...")
        try:
            report1 = Report(metrics=[ClassificationPreset()])
            report1.run(reference_data=train_df, current_data=test_df)

            report1_path = os.path.join(
                REPORTS_PATH, f"run_{run_id}_classification_report.html"
            )
            report1.save_html(report1_path)
            reports_paths["classification"] = report1_path
            logger.info(f"  - Guardado en: {report1_path}")
        except Exception as e:
            logger.warning(f"⚠ Error generando reporte de clasificación: {str(e)}")

        # --------- Reporte 2: Data Drift ---------
        logger.info("✓ Generando reporte de data drift...")
        try:
            report2 = Report(metrics=[DataDriftPreset()])
            report2.run(reference_data=train_df, current_data=test_df)

            report2_path = os.path.join(REPORTS_PATH, f"run_{run_id}_drift_report.html")
            report2.save_html(report2_path)
            reports_paths["drift"] = report2_path
            logger.info(f"  - Guardado en: {report2_path}")
        except Exception as e:
            logger.warning(f"⚠ Error generando reporte de drift: {str(e)}")

        logger.info("\n✓ Reportes Evidently generados exitosamente")

    except Exception as e:
        logger.error(f"✗ Error generando reportes: {str(e)}")
        reports_paths = {}

    return reports_paths


# =============================
# PASO 8: ENVIAR DATOS A EVIDENTLY SERVICE
# =============================
def send_to_evidently_service(
    X_train, X_test, y_train, y_test, y_pred, feature_names, run_id
):
    """
    Envía datos a Evidently Service API para monitoreo en tiempo real.

    Args:
        X_train, X_test (np.array): Features
        y_train, y_test (np.array): Targets
        y_pred (np.array): Predicciones
        feature_names (list): Nombres de features
        run_id (str): ID del run
    """
    logger.info("=" * 60)
    logger.info("PASO 8: ENVIAR DATOS A EVIDENTLY SERVICE")
    logger.info("=" * 60)

    try:
        # URL del servicio
        service_url = f"{EVIDENTLY_SERVICE_URL}/api"
        logger.info(f"✓ Conectando a Evidently Service: {service_url}")

        # Preparar datos
        train_df = pd.DataFrame(X_train, columns=feature_names)
        train_df["target"] = y_train

        test_df = pd.DataFrame(X_test, columns=feature_names)
        test_df["target"] = y_test
        test_df["prediction"] = y_pred

        # Crear proyecto de monitoreo
        project_name = f"clase-3-{run_id[:8]}"

        try:
            # Intentar obtener proyecto existente
            response = requests.get(f"{service_url}/projects")
            projects = response.json()
            project_exists = any(p.get("name") == project_name for p in projects)

            if not project_exists:
                # Crear nuevo proyecto
                project_data = {
                    "name": project_name,
                    "description": f"Run {run_id} - Monitoreo Clase 3",
                }
                requests.post(f"{service_url}/projects", json=project_data)
                logger.info(f"✓ Proyecto creado: {project_name}")
            else:
                logger.info(f"✓ Usando proyecto existente: {project_name}")
        except Exception as e:
            logger.warning(
                f"⚠ No se pudo crear proyecto en Evidently Service: {str(e)}"
            )

        logger.info("✓ Datos enviados a Evidently Service")

    except Exception as e:
        logger.warning(f"⚠ Error enviando datos a Evidently Service: {str(e)}")


# =============================
# PASO 9: RESUMEN Y URLS
# =============================
def print_summary(run_id, reports_paths):
    """
    Imprime resumen final con URLs de acceso.

    Args:
        run_id (str): ID del run
        reports_paths (dict): Rutas de reportes
    """
    logger.info("=" * 60)
    logger.info("RESUMEN FINAL Y URLS DE ACCESO")
    logger.info("=" * 60)

    logger.info(f"\n✓ Run ID: {run_id}")
    logger.info(f"✓ Timestamp: {datetime.now().isoformat()}")

    logger.info("\n📊 INTERFACES WEB:")
    logger.info("  - MLflow UI:           http://localhost:5000")
    logger.info("  - Evidently Dashboard: http://localhost:8000")

    logger.info("\n📄 REPORTES HTML LOCALES:")
    for report_type, path in reports_paths.items():
        logger.info(f"  - {report_type.capitalize()}: {path}")

    logger.info("\n💡 PRÓXIMOS PASOS:")
    logger.info("  1. Abre http://localhost:5000 para ver el modelo en MLflow")
    logger.info("  2. Abre http://localhost:8000 para ver el dashboard de Evidently")
    logger.info(
        "  3. Ejecuta 'docker-compose exec monitoring python simulate_drift.py'"
    )
    logger.info("  4. Compara múltiples runs en MLflow UI")
    logger.info("\n" + "=" * 60 + "\n")


# =============================
# FUNCIÓN PRINCIPAL
# =============================
def main():
    """Función principal que orquesta todo el workflow."""

    try:
        logger.info("\n" + "█" * 60)
        logger.info("█" + " " * 58 + "█")
        logger.info(
            "█" + "  CLASE 3: MODEL MONITORING CON EVIDENTLY + MLflow".center(58) + "█"
        )
        logger.info("█" + " " * 58 + "█")
        logger.info("█" * 60 + "\n")

        # PASO 1: Cargar datos (Iris)
        X, y, feature_names, df = load_and_prepare_data()

        # PASO 2: Split
        X_train, X_test, y_train, y_test = split_data(X, y)

        # PASO 3: Entrenar modelo
        hyperparams = {
            "n_estimators": 100,
            "max_depth": 10,
            "min_samples_split": 5,
            "min_samples_leaf": 2,
            "random_state": 39758307,
            "n_jobs": -1,
        }
        model, cv_scores = train_model(X_train, y_train, hyperparams)

        # PASO 4: Evaluar
        metrics, y_pred, y_pred_proba = evaluate_model(
            model, X_test, y_test, feature_names
        )

        # PASO 5: Configurar MLflow
        experiment_id = setup_mlflow()

        # PASO 6: Log a MLflow
        run_id = log_to_mlflow(
            experiment_id,
            model,
            hyperparams,
            metrics,
            cv_scores,
            X_test,
            y_test,
            y_pred,
        )

        # PASO 7: Generar reportes Evidently
        reports_paths = generate_evidently_reports(
            model, X_train, X_test, y_train, y_test, y_pred, feature_names, run_id
        )

        # PASO 8: Enviar a Evidently Service
        send_to_evidently_service(
            X_train, X_test, y_train, y_test, y_pred, feature_names, run_id
        )

        # PASO 9: Resumen
        print_summary(run_id, reports_paths)

        logger.info("✓ WORKFLOW COMPLETADO EXITOSAMENTE\n")

    except Exception as e:
        logger.error(f"\n✗ ERROR EN WORKFLOW: {str(e)}")
        raise


if __name__ == "__main__":
    main()
