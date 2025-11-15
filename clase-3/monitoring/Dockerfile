FROM python:3.11-slim

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Crear directorios necesarios
RUN mkdir -p /app/data /app/reports

# Permiso para ejecutar scripts
RUN chmod +x /app/*.py 2>/dev/null || true

# Exponer puerto (en caso de necesitarse en futuro)
EXPOSE 5000

# Comando interactivo para desarrollo
CMD ["/bin/bash"]

