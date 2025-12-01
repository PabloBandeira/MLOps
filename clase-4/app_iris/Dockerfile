# ==================================================
# STAGE 1: BUILD - Entrenar el modelo
# ==================================================
# En esta etapa entrenamos el modelo y lo guardamos.
# El modelo queda "cocinado" dentro de la imagen.

FROM python:3.9-slim AS builder

WORKDIR /app

# Copiar archivos de entrenamiento
COPY requirements.txt train.py ./

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Entrenar el modelo (se ejecuta durante el build)
# Esto crea /app/model.joblib
RUN python train.py

# Verificar que el modelo se creó correctamente
RUN ls -lh /app/model.joblib && echo "✅ Modelo creado exitosamente"

# ==================================================
# STAGE 2: RUNTIME - Servir el modelo
# ==================================================
# Esta etapa copia el modelo entrenado y ejecuta la API

FROM python:3.9-slim

WORKDIR /app

# Copiar requirements (para la API)
COPY requirements.txt ./

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el modelo entrenado desde el stage anterior
COPY --from=builder /app/model.joblib /app/model.joblib

# Copiar el código de la API
COPY main.py ./

# Verificar que todo está en su lugar
RUN ls -lh /app/ && echo "✅ Imagen lista"

# Exponer puerto
EXPOSE 8000

# Health check (para Kubernetes)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Comando para iniciar la API
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
