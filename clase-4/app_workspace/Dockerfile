# ==================================================
# Workspace Jupyter para el alumno
# ==================================================
# Entorno completo con todas las librerías necesarias
# para interactuar con los servicios de MLOps

FROM python:3.9-slim

WORKDIR /app

# Instalar dependencias del sistema
# Incluimos gcc y python3-dev para compilar psutil y otras librerías
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Crear directorio para notebooks
RUN mkdir -p /app/notebooks

# Copiar notebooks al contenedor
# NOTA: Los notebooks deben estar en ../notebooks/ relativo a este Dockerfile
COPY ../notebooks/*.ipynb /app/notebooks/ 2>/dev/null || true

# Configurar Jupyter
# - Sin token de autenticación (para simplicidad pedagógica)
# - Permitir root (necesario en algunos entornos)
RUN mkdir -p /root/.jupyter && \
    echo "c.ServerApp.token = ''" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py

# Exponer puerto de Jupyter
EXPOSE 8888

# Iniciar JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
