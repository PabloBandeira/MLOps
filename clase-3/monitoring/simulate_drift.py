"""
Script de Simulación de Drift: Detección de cambios en distribuciones

Este script simula diferentes tipos de drift en datos y genera reportes
comparativos con Evidently AI, demostrando capacidades de monitoreo.

Tipos de drift simulados:
  1. SIN DRIFT: Datos con distribución similar (baseline)
  2. COVARIATE SHIFT: Cambio en distribución de features
  3. LABEL SHIFT: Cambio en proporciones de clases
  4. FEATURE DRIFT: Cambio en rangos y escala de features

Uso:
    docker-compose exec monitoring python simulate_drift.py
    
Salida:
    - Reportes HTML comparativos en /app/reports/
    - Runs en MLflow con tags de drift_type
"""

import os
import logging
import numpy as np
import pandas as pd
import warnings

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import load_iris
from sklearn.metrics import accuracy_score, f1_score

import mlflow
import mlflow.sklearn
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset

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

os.makedirs(REPORTS_PATH, exist_ok=True)


# =============================
# CARGAR DATOS BASE (IRIS)
# =============================
def load_reference_data():
    """
    Carga el dataset Iris como datos de referencia.

    Returns:
        tuple: (X_train, X_test, y_train, y_test, feature_names)
    """
    logger.info("Cargando dataset Iris...")

    iris = load_iris()
    X = iris.data
    y = iris.target
    feature_names = list(iris.feature_names)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=39758307
    )

    logger.info(f"✓ Dataset Iris cargado: {X_train.shape}")
    logger.info(f"✓ Features: {len(feature_names)}\n")

    return X_train, X_test, y_train, y_test, feature_names


# =============================
# SCENARIO 1: SIN DRIFT (BASELINE)
# =============================
def generate_baseline_data(X_test, y_test, feature_names, n_samples=100):
    """
    Genera datos SIN drift (distribución similar a test).

    Args:
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        feature_names (list): Nombres de features
        n_samples (int): Número de muestras nuevas

    Returns:
        tuple: (X_baseline, y_baseline, df_baseline)
    """
    logger.info("=" * 60)
    logger.info("SCENARIO 1: SIN DRIFT (BASELINE)")
    logger.info("=" * 60)

    # Seleccionar muestras aleatorias del conjunto de test
    indices = np.random.choice(len(X_test), size=n_samples, replace=True)
    X_baseline = X_test[indices] + np.random.normal(0, 0.01, X_test[indices].shape)
    y_baseline = y_test[indices]

    df_baseline = pd.DataFrame(X_baseline, columns=feature_names)
    df_baseline["target"] = y_baseline
    df_baseline["prediction"] = y_baseline  # Simulamos predicciones correctas

    logger.info(f"✓ {len(X_baseline)} muestras sin drift generadas")
    logger.info("✓ Distribución de clases:")
    for cls in np.unique(y_baseline):
        count = (y_baseline == cls).sum()
        logger.info(
            f"  - Clase {int(cls)}: {count} ({100*count/len(y_baseline):.1f}%)\n"
        )

    return X_baseline, y_baseline, df_baseline


# =============================
# SCENARIO 2: COVARIATE SHIFT
# =============================
def generate_covariate_shift_data(X_test, y_test, feature_names, n_samples=100):
    """
    Genera datos con COVARIATE SHIFT (cambio en distribución de features).

    Args:
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        feature_names (list): Nombres de features
        n_samples (int): Número de muestras nuevas

    Returns:
        tuple: (X_drifted, y_drifted, df_drifted)
    """
    logger.info("=" * 60)
    logger.info("SCENARIO 2: COVARIATE SHIFT (cambio en features)")
    logger.info("=" * 60)

    # Desplazar media y varianza de features
    X_drifted = X_test.copy()

    # Seleccionar muestras y aplicar drift
    indices = np.random.choice(len(X_test), size=n_samples, replace=True)
    X_drifted = X_test[indices].copy().astype(float)

    # Shift: aumentar media de features
    shift_magnitude = 0.5  # Magnitud del shift
    for i in range(X_drifted.shape[1]):
        X_drifted[:, i] = X_drifted[:, i] + np.random.normal(
            shift_magnitude, 0.2, n_samples
        )

    # Mantener targets igual (para simular cambio en features, no en target)
    y_drifted = y_test[indices]

    df_drifted = pd.DataFrame(X_drifted, columns=feature_names)
    df_drifted["target"] = y_drifted
    df_drifted["prediction"] = y_drifted

    logger.info(f"✓ {len(X_drifted)} muestras con covariate shift generadas")
    logger.info("✓ Drift aplicado:")
    logger.info(f"  - Media shift: +{shift_magnitude}")
    logger.info("  - Afecta todos los features\n")

    return X_drifted, y_drifted, df_drifted


# =============================
# SCENARIO 3: LABEL SHIFT
# =============================
def generate_label_shift_data(X_test, y_test, feature_names, n_samples=100):
    """
    Genera datos con LABEL SHIFT (cambio en proporción de clases).

    Args:
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        feature_names (list): Nombres de features
        n_samples (int): Número de muestras nuevas

    Returns:
        tuple: (X_shifted, y_shifted, df_shifted)
    """
    logger.info("=" * 60)
    logger.info("SCENARIO 3: LABEL SHIFT (cambio en proporción de clases)")
    logger.info("=" * 60)

    # Cambiar distribución de clases (invertir proporción)
    X_shifted = []
    y_shifted = []

    # Clase 0: 80%, Clase 1: 20% (opuesto a lo usual)
    class_0_count = int(0.8 * n_samples)
    class_1_count = n_samples - class_0_count

    indices_0 = np.random.choice(
        np.where(y_test == 0)[0], size=class_0_count, replace=True
    )
    indices_1 = np.random.choice(
        np.where(y_test == 1)[0], size=class_1_count, replace=True
    )

    X_shifted = np.vstack([X_test[indices_0], X_test[indices_1]])
    y_shifted = np.concatenate([y_test[indices_0], y_test[indices_1]])

    df_shifted = pd.DataFrame(X_shifted, columns=feature_names)
    df_shifted["target"] = y_shifted
    df_shifted["prediction"] = y_shifted

    logger.info(f"✓ {len(X_shifted)} muestras con label shift generadas")
    logger.info("✓ Nueva distribución de clases:")
    for cls in np.unique(y_shifted):
        count = (y_shifted == cls).sum()
        logger.info(
            f"  - Clase {int(cls)}: {count} ({100*count/len(y_shifted):.1f}%)\n"
        )

    return X_shifted, y_shifted, df_shifted


# =============================
# SCENARIO 4: FEATURE DRIFT
# =============================
def generate_feature_drift_data(X_test, y_test, feature_names, n_samples=100):
    """
    Genera datos con FEATURE DRIFT (outliers, ruido, cambio de escala).

    Args:
        X_test (np.array): Features de test
        y_test (np.array): Target de test
        feature_names (list): Nombres de features
        n_samples (int): Número de muestras nuevas

    Returns:
        tuple: (X_drifted, y_drifted, df_drifted)
    """
    logger.info("=" * 60)
    logger.info("SCENARIO 4: FEATURE DRIFT (outliers y cambios de escala)")
    logger.info("=" * 60)

    indices = np.random.choice(len(X_test), size=n_samples, replace=True)
    X_drifted = X_test[indices].copy().astype(float)
    y_drifted = y_test[indices]

    # Agregar outliers (10% de datos)
    outlier_indices = np.random.choice(
        n_samples, size=int(0.1 * n_samples), replace=False
    )
    for idx in outlier_indices:
        feature_idx = np.random.randint(0, X_drifted.shape[1])
        X_drifted[idx, feature_idx] = np.random.uniform(-3, 3)

    # Agregar ruido gaussiano
    X_drifted = X_drifted + np.random.normal(0, 0.3, X_drifted.shape)

    # Agregar valores faltantes simulados (reemplazar con media)
    missing_indices = np.random.choice(
        n_samples, size=int(0.05 * n_samples), replace=False
    )
    for idx in missing_indices:
        feature_idx = np.random.randint(0, X_drifted.shape[1])
        X_drifted[idx, feature_idx] = np.mean(X_drifted[:, feature_idx])

    df_drifted = pd.DataFrame(X_drifted, columns=feature_names)
    df_drifted["target"] = y_drifted
    df_drifted["prediction"] = y_drifted

    logger.info(f"✓ {len(X_drifted)} muestras con feature drift generadas")
    logger.info("✓ Drift aplicado:")
    logger.info("  - 10% outliers introducidos")
    logger.info("  - Ruido gaussiano (std=0.3)")
    logger.info("  - 5% valores faltantes simulados\n")

    return X_drifted, y_drifted, df_drifted


# =============================
# GENERAR REPORTES EVIDENTLY
# =============================
def generate_drift_report(model, X_train, df_scenario, scenario_name, run_id):
    """
    Genera reporte Evidently comparando training data vs scenario.

    Args:
        model: Modelo entrenado para generar predicciones
        X_train (np.array): Datos de referencia (training)
        df_scenario (pd.DataFrame): Datos del escenario
        scenario_name (str): Nombre del escenario
        run_id (str): ID único del run

    Returns:
        str: Ruta del reporte HTML
    """
    logger.info(f"Generando reporte Evidently para: {scenario_name}...")

    # Preparar datos de referencia
    feature_names = [
        col for col in df_scenario.columns if col not in ["target", "prediction"]
    ]
    df_train = pd.DataFrame(X_train, columns=feature_names)
    df_train["target"] = 0  # Placeholder
    df_train["prediction"] = model.predict(X_train)  # Agregar predicciones

    # Crear reporte
    try:
        report = Report(metrics=[DataDriftPreset()])
        report.run(reference_data=df_train, current_data=df_scenario)
    except Exception as e:
        logger.warning(f"⚠ Error generando reporte: {e}")
        return None

    # Guardar
    report_name = scenario_name.lower().replace(" ", "_")
    report_path = os.path.join(REPORTS_PATH, f"drift_{report_name}_{run_id[:8]}.html")
    report.save_html(report_path)

    logger.info(f"✓ Reporte guardado: {report_path}\n")

    return report_path


# =============================
# LOGGING EN MLflow
# =============================
def log_scenario_to_mlflow(
    scenario_name,
    drift_type,
    drift_severity,
    X_train,
    X_test,
    y_test,
    y_pred,
    df_reference,
):
    """
    Registra un escenario de drift en MLflow.

    Args:
        scenario_name (str): Nombre del escenario
        drift_type (str): Tipo de drift
        drift_severity (str): Severidad del drift
        X_train, X_test (np.array): Features
        y_test, y_pred (np.array): Targets y predicciones
        df_reference (pd.DataFrame): DataFrame de referencia
    """
    # Configurar MLflow
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

    try:
        experiment = mlflow.get_experiment_by_name("Model Monitoring - Clase 3")
        experiment_id = experiment.experiment_id
    except Exception:
        experiment_id = mlflow.create_experiment("Model Monitoring - Clase 3")

    # Iniciar run
    with mlflow.start_run(experiment_id=experiment_id):
        # Log parámetros
        mlflow.log_param("scenario", scenario_name)
        mlflow.log_param("drift_type", drift_type)
        mlflow.log_param("drift_severity", drift_severity)
        mlflow.log_param("n_samples", len(X_test))

        # Log métricas (weighted para multiclass)
        y_pred_labels = y_pred.round().astype(int)
        accuracy = accuracy_score(y_test, y_pred_labels)
        f1 = f1_score(y_test, y_pred_labels, average="weighted", zero_division=0)

        mlflow.log_metric("accuracy", accuracy)
        mlflow.log_metric("f1_score", f1)

        # Log tags
        mlflow.set_tag("run_type", "drift_simulation")
        mlflow.set_tag("drift_type", drift_type)
        mlflow.set_tag("drift_severity", drift_severity)

        run_id = mlflow.active_run().info.run_id
        logger.info(f"✓ {scenario_name} registrado en MLflow (Run ID: {run_id[:8]})\n")

        return run_id


# =============================
# FUNCIÓN PRINCIPAL
# =============================
def main():
    """Función principal que orquesta simulación de drift."""

    logger.info("\n" + "█" * 60)
    logger.info("█" + " " * 58 + "█")
    logger.info("█" + "  SIMULACIÓN DE DRIFT - CLASE 3".center(58) + "█")
    logger.info("█" + " " * 58 + "█")
    logger.info("█" * 60 + "\n")

    # Cargar datos base (Iris)
    X_train, X_test, y_train, y_test, feature_names = load_reference_data()
    logger.info(f"{'=' * 60}\n")

    # Entrenar modelo base para predicciones
    model = RandomForestClassifier(
        n_estimators=100, max_depth=10, random_state=39758307
    )
    model.fit(X_train, y_train)

    import uuid

    run_id = str(uuid.uuid4())

    # ========================================
    # SCENARIO 1: SIN DRIFT
    # ========================================
    logger.info("ESCENARIO 1: SIN DRIFT (BASELINE)")
    logger.info("-" * 60)
    X_baseline, y_baseline, df_baseline = generate_baseline_data(
        X_test, y_test, feature_names
    )
    y_pred_baseline = model.predict(X_baseline)

    report1 = generate_drift_report(
        model, X_train, df_baseline, "Scenario 1: Sin Drift", run_id
    )
    log_scenario_to_mlflow(
        "Scenario 1: Sin Drift",
        "none",
        "low",
        X_train,
        X_baseline,
        y_baseline,
        y_pred_baseline,
        df_baseline,
    )

    # ========================================
    # SCENARIO 2: COVARIATE SHIFT
    # ========================================
    logger.info("ESCENARIO 2: COVARIATE SHIFT")
    logger.info("-" * 60)
    X_covariate, y_covariate, df_covariate = generate_covariate_shift_data(
        X_test, y_test, feature_names
    )
    y_pred_covariate = model.predict(X_covariate)

    report2 = generate_drift_report(
        model, X_train, df_covariate, "Scenario 2: Covariate Shift", run_id
    )
    log_scenario_to_mlflow(
        "Scenario 2: Covariate Shift",
        "covariate",
        "high",
        X_train,
        X_covariate,
        y_covariate,
        y_pred_covariate,
        df_covariate,
    )

    # ========================================
    # SCENARIO 3: LABEL SHIFT
    # ========================================
    logger.info("ESCENARIO 3: LABEL SHIFT")
    logger.info("-" * 60)
    X_label, y_label, df_label = generate_label_shift_data(
        X_test, y_test, feature_names
    )
    y_pred_label = model.predict(X_label)

    report3 = generate_drift_report(
        model, X_train, df_label, "Scenario 3: Label Shift", run_id
    )
    log_scenario_to_mlflow(
        "Scenario 3: Label Shift",
        "label",
        "high",
        X_train,
        X_label,
        y_label,
        y_pred_label,
        df_label,
    )

    # ========================================
    # SCENARIO 4: FEATURE DRIFT
    # ========================================
    logger.info("ESCENARIO 4: FEATURE DRIFT")
    logger.info("-" * 60)
    X_feature, y_feature, df_feature = generate_feature_drift_data(
        X_test, y_test, feature_names
    )
    y_pred_feature = model.predict(X_feature)

    report4 = generate_drift_report(
        model, X_train, df_feature, "Scenario 4: Feature Drift", run_id
    )
    log_scenario_to_mlflow(
        "Scenario 4: Feature Drift",
        "feature",
        "medium",
        X_train,
        X_feature,
        y_feature,
        y_pred_feature,
        df_feature,
    )

    # ========================================
    # RESUMEN FINAL
    # ========================================
    logger.info("=" * 60)
    logger.info("RESUMEN DE SIMULACIÓN DE DRIFT")
    logger.info("=" * 60)
    logger.info("\n✓ Simulación completada exitosamente")
    logger.info("\n📊 Reportes generados:")
    logger.info(f"  - Scenario 1 (Sin Drift):        {report1}")
    logger.info(f"  - Scenario 2 (Covariate Shift):  {report2}")
    logger.info(f"  - Scenario 3 (Label Shift):      {report3}")
    logger.info(f"  - Scenario 4 (Feature Drift):    {report4}")

    logger.info("\n📈 Runs en MLflow:")
    logger.info("  - Ver en: http://localhost:5000")
    logger.info("  - Buscar experimento: 'Model Monitoring - Clase 3'")
    logger.info("  - Observar tags: 'drift_type' y 'drift_severity'")

    logger.info("\n💡 Para comparar visualmente:")
    logger.info("  - Abre http://localhost:8000 para ver dashboards")
    logger.info("  - Abre los reportes HTML en tu navegador")
    logger.info("  - Compara métricas entre escenarios en MLflow UI")

    logger.info("\n✓ WORKFLOW DE DRIFT SIMULATION COMPLETADO\n")


if __name__ == "__main__":
    main()
