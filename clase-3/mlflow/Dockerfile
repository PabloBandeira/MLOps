FROM python:3.11-slim

WORKDIR /app

# Instalar utilidades del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar MLflow y dependencias necesarias
RUN pip install --no-cache-dir \
    mlflow==2.12.1 \
    numpy==1.24.3 \
    pandas==2.0.3 \
    scikit-learn==1.3.0

# Crear directorio de datos
RUN mkdir -p /mlflow_data/artifacts

# Exponer puerto
EXPOSE 5000

# Comando por defecto: iniciar servidor MLflow
CMD ["mlflow", "server", \
     "--host", "0.0.0.0", \
     "--port", "5000", \
     "--backend-store-uri", "sqlite:////mlflow_data/mlflow.db", \
     "--default-artifact-root", "/mlflow_data/artifacts"]

