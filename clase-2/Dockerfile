FROM python:3.11-slim

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente y scripts
COPY src/ ./src/
COPY scripts/ ./scripts/

# Exponer puerto para MLflow serving (opcional)
EXPOSE 9000

# Comando por defecto
CMD ["python", "src/train.py"]

