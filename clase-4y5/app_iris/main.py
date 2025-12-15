"""
API de inferencia para el modelo Iris.
Carga el modelo entrenado durante el build y expone endpoints REST.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import joblib
import numpy as np
import os
from typing import Dict
import logging
import uuid
from datetime import datetime

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Inicializar FastAPI
app = FastAPI(
    title="Iris Prediction API",
    description="API de inferencia para clasificación de flores Iris",
    version="1.0.0",
)

# Variable global para el modelo
MODEL = None
MODEL_METADATA = {}


# Schema de entrada
class IrisFeatures(BaseModel):
    sepal_length: float = Field(
        ..., ge=0, le=10, description="Longitud del sépalo (cm)"
    )
    sepal_width: float = Field(..., ge=0, le=10, description="Ancho del sépalo (cm)")
    petal_length: float = Field(
        ..., ge=0, le=10, description="Longitud del pétalo (cm)"
    )
    petal_width: float = Field(..., ge=0, le=10, description="Ancho del pétalo (cm)")

    class Config:
        json_schema_extra = {
            "example": {
                "sepal_length": 5.1,
                "sepal_width": 3.5,
                "petal_length": 1.4,
                "petal_width": 0.2,
            }
        }


# Schema de salida
class PredictionResponse(BaseModel):
    prediction: int = Field(..., description="Clase predicha (0, 1, 2)")
    prediction_label: str = Field(..., description="Nombre de la clase")
    confidence: float = Field(..., description="Confianza de la predicción")
    probabilities: Dict[str, float] = Field(..., description="Probabilidades por clase")
    model_version: str = Field(..., description="Versión del modelo")
    features_used: Dict[str, float] = Field(..., description="Features utilizadas")
    prediction_id: str = Field(..., description="ID único de la predicción")
    timestamp: str = Field(..., description="Timestamp de la predicción (ISO 8601)")


def load_model():
    """
    Carga el modelo desde el archivo model.joblib.
    Este archivo fue creado durante el docker build.
    """
    global MODEL, MODEL_METADATA

    model_path = "/app/model.joblib"

    if not os.path.exists(model_path):
        raise FileNotFoundError(
            f"Modelo no encontrado en {model_path}. "
            "Asegúrate de que train.py se ejecutó durante el build."
        )

    logger.info(f"📦 Cargando modelo desde {model_path}...")

    try:
        model_artifact = joblib.load(model_path)
        MODEL = model_artifact["model"]
        MODEL_METADATA = {
            "feature_names": model_artifact["feature_names"],
            "target_names": model_artifact["target_names"],
            "accuracy": model_artifact["accuracy"],
            "version": model_artifact["version"],
        }

        logger.info("✅ Modelo cargado exitosamente")
        logger.info(f"   Versión: {MODEL_METADATA['version']}")
        logger.info(f"   Accuracy: {MODEL_METADATA['accuracy']:.4f}")
        logger.info(f"   Clases: {MODEL_METADATA['target_names']}")

    except Exception as e:
        logger.error(f"❌ Error al cargar el modelo: {e}")
        raise


@app.on_event("startup")
async def startup_event():
    """Evento que se ejecuta al iniciar la API"""
    logger.info("🚀 Iniciando Iris Prediction API...")
    load_model()
    logger.info("✅ API lista para recibir peticiones")


@app.get("/")
async def root():
    """Endpoint raíz - información del servicio"""
    return {
        "service": "Iris Prediction API",
        "version": "1.0.0",
        "status": "running",
        "model_loaded": MODEL is not None,
        "endpoints": {"predict": "/predict", "health": "/health", "info": "/info"},
    }


@app.get("/health")
async def health_check():
    """Endpoint de health check para Kubernetes"""
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Modelo no cargado")

    return {
        "status": "healthy",
        "model_loaded": True,
        "model_version": MODEL_METADATA.get("version", "unknown"),
    }


@app.get("/info")
async def model_info():
    """Información sobre el modelo cargado"""
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Modelo no cargado")

    return {
        "model_type": "RandomForestClassifier",
        "version": MODEL_METADATA.get("version", "unknown"),
        "accuracy": MODEL_METADATA.get("accuracy", None),
        "feature_names": MODEL_METADATA.get("feature_names", []),
        "target_names": MODEL_METADATA.get("target_names", []),
        "n_estimators": MODEL.n_estimators if hasattr(MODEL, "n_estimators") else None,
        "max_depth": MODEL.max_depth if hasattr(MODEL, "max_depth") else None,
    }


@app.post("/predict", response_model=PredictionResponse)
async def predict(features: IrisFeatures):
    """
    Endpoint de predicción.

    Recibe las características de una flor Iris y retorna la clase predicha.
    """
    if MODEL is None:
        raise HTTPException(status_code=503, detail="Modelo no cargado")

    try:
        # Convertir features a array
        feature_array = np.array(
            [
                [
                    features.sepal_length,
                    features.sepal_width,
                    features.petal_length,
                    features.petal_width,
                ]
            ]
        )

        # Realizar predicción
        prediction = MODEL.predict(feature_array)[0]
        probabilities = MODEL.predict_proba(feature_array)[0]

        # Obtener etiqueta de la clase
        target_names = MODEL_METADATA.get("target_names", ["0", "1", "2"])
        prediction_label = target_names[prediction]

        # Confianza (máxima probabilidad)
        confidence = float(probabilities[prediction])

        # Crear diccionario de probabilidades
        prob_dict = {
            target_names[i]: float(prob) for i, prob in enumerate(probabilities)
        }

        # Features utilizadas
        feature_names = MODEL_METADATA.get(
            "feature_names",
            ["sepal_length", "sepal_width", "petal_length", "petal_width"],
        )
        features_dict = {
            feature_names[0]: features.sepal_length,
            feature_names[1]: features.sepal_width,
            feature_names[2]: features.petal_length,
            feature_names[3]: features.petal_width,
        }

        logger.info(
            f"Predicción realizada: {prediction_label} "
            f"(confianza: {confidence:.4f})"
        )

        # Generar ID único y timestamp
        prediction_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat() + "Z"

        return PredictionResponse(
            prediction=int(prediction),
            prediction_label=prediction_label,
            confidence=confidence,
            probabilities=prob_dict,
            model_version=MODEL_METADATA.get("version", "1.0.0"),
            features_used=features_dict,
            prediction_id=prediction_id,
            timestamp=timestamp,
        )

    except Exception as e:
        logger.error(f"Error en la predicción: {e}")
        raise HTTPException(status_code=500, detail=f"Error en la predicción: {str(e)}")


@app.get("/metrics")
async def metrics():
    """
    Endpoint básico de métricas (para monitoreo futuro con Prometheus)
    """
    return {
        "model_version": MODEL_METADATA.get("version", "unknown"),
        "model_accuracy": MODEL_METADATA.get("accuracy", None),
        "service_status": "running",
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
