# serve_mlflow_model.py
from flask import Flask, request, jsonify
import mlflow
import mlflow.sklearn
import numpy as np

# ------------------------------------------------------------
# CONFIGURACIÓN
# ------------------------------------------------------------
app = Flask(__name__)

# Ruta del modelo MLflow (puede ser local o de un run)
# Ejemplo: "outputs5/linear_model" o "runs:/<run_id>/model"
model_path = "outputs5/linear_model"

# Cargar el modelo desde MLflow
try:
    loaded_model = mlflow.sklearn.load_model(model_path)
    print(f"✅ Modelo cargado correctamente desde: {model_path}")
except Exception as e:
    print(f"❌ Error al cargar el modelo: {e}")
    loaded_model = None


# ------------------------------------------------------------
# ENDPOINTS
# ------------------------------------------------------------
@app.route('/')
def home():
    """Endpoint base de bienvenida"""
    return jsonify({
        "message": "API de predicción con MLflow y Flask",
        "status": "ok",
        "model_path": model_path
    })

@app.route('/health', methods=['GET'])
def health():
    """Verifica que el modelo esté disponible"""
    status = "ready" if loaded_model else "model_not_loaded"
    return jsonify({"status": status})

@app.route('/predict', methods=['POST'])
def predict():
    """Recibe datos en JSON y devuelve predicciones"""
    if loaded_model is None:
        return jsonify({"error": "El modelo no está cargado"}), 500

    try:
        # Espera un JSON con formato {"data": [[...], [...]]}
        input_json = request.get_json()
        if "data" not in input_json:
            return jsonify({"error": "Falta la clave 'data' en el JSON"}), 400

        # Convertir a numpy array
        X_input = np.array(input_json["data"])
        preds = loaded_model.predict(X_input)

        # Opcional: si el modelo tiene predict_proba
        proba = None
        if hasattr(loaded_model, "predict_proba"):
            proba = loaded_model.predict_proba(X_input).tolist()

        return jsonify({
            "predictions": preds.tolist(),
            "probabilities": proba,
            "n_samples": len(preds),
            "status": "ok"
        })
    except Exception as e:
        return jsonify({"error": str(e), "status": "failed"}), 500


# ------------------------------------------------------------
# MAIN
# ------------------------------------------------------------
if __name__ == '__main__':
    # Ejecutar el servidor Flask
    # host='0.0.0.0' permite que sea accesible externamente (útil en Databricks o Docker)
    app.run(host='0.0.0.0', port=5001, debug=True)
