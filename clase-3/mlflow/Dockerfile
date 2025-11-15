FROM python:3.11-slim

WORKDIR /app

# Instalar utilidades del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Instalar MLflow y dependencias necesarias (últimas versiones)
RUN pip install --no-cache-dir \
    mlflow==3.6.0 \
    numpy==1.26.4 \
    pandas==2.2.0 \
    scikit-learn==1.5.1

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

