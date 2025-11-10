FROM python:3.11-slim

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY src/ ./src/
COPY scripts/ ./scripts/

# Crear directorio para MLflow
RUN mkdir -p /app/mlruns

# Exponer puertos
# 5000: MLflow UI
# 9000: MLflow Model Serving
EXPOSE 5000 9000

# Comando por defecto: ejecutar el script de inicio
CMD ["bash", "scripts/docker-entrypoint.sh"]

