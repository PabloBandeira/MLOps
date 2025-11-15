# Setup para macOS - Clase 3

Guía específica para usuarios de macOS.

## Verificar Instalación

### Docker Desktop

```bash
# Verificar que Docker está instalado
docker --version
# Salida esperada: Docker version 20.10.x o superior

# Verificar Docker Compose
docker-compose --version
# Salida esperada: Docker Compose version 2.x.x

# Iniciar Docker Desktop (si no está corriendo)
# Menu > Docker > Click en el icono
```

## Primer Inicio

### Paso 1: Navegación

```bash
cd /Users/pablo/Desktop/MLops/clase-3
```

### Paso 2: Construir e Iniciar Servicios

```bash
# Construir imágenes (primera vez es más lenta)
docker-compose build

# Iniciar servicios en background
docker-compose up -d

# Verificar que todo está corriendo
docker-compose ps
```

**Salida esperada:**

```
NAME                  STATUS
mlflow-server         running
evidently-service     running
monitoring-app        running
```

### Paso 3: Esperar a que servicios estén listos

```bash
# Ver logs de MLflow
docker-compose logs mlflow

# Cuando veas "Listening on" → listo
# Esto toma ~20-30 segundos

# Ctrl+C para salir de logs
```

### Paso 4: Ejecutar Entrenamiento

```bash
# Entrenar modelo
docker-compose exec monitoring python train_and_monitor.py
```

### Paso 5: Abrir en Navegador

En macOS, automáticamente:

```bash
# Opción 1: Terminal
open http://localhost:5000

# Opción 2: Safari/Chrome
# Copiar y pegar: http://localhost:5000
```

## Comandos Útiles para macOS

### Ver logs en tiempo real

```bash
docker-compose logs -f monitoring
```

Presiona `Ctrl+C` para salir.

### Entrar a shell del contenedor

```bash
docker-compose exec monitoring bash

# Dentro del contenedor:
ls -la
python --version
exit
```

### Gestionar recursos de Docker

```bash
# Ver cuánta CPU y memoria usa Docker
docker stats

# Si Docker va lento:
# 1. Abre Docker Desktop
# 2. Preferences > Resources
# 3. Aumenta CPU y Memory
```

### Resetear volúmenes (borra datos)

```bash
# Detener servicios
docker-compose down -v

# Reiniciar limpio
docker-compose up -d
```

## Troubleshooting macOS

### Problema: "Cannot connect to Docker daemon"

**Solución:**
```bash
# Asegúrate que Docker Desktop está corriendo
# Abre Applications > Docker.app

# O inicia desde terminal
open -a Docker
```

### Problema: "Permission denied" en volúmenes

**Solución:**
```bash
# macOS no tiene este problema típicamente
# Si ocurre, reset de Docker:
# Docker > Preferences > Reset
```

### Problema: "Port 5000 already in use"

```bash
# Encontrar qué proceso usa el puerto
lsof -i :5000

# Matar el proceso
kill -9 <PID>

# O cambiar puerto en docker-compose.yml
# mlflow:
#   ports:
#     - "5001:5000"  # Cambiar a 5001
```

### Problema: "Out of memory"

**Solución:**
```bash
# Docker > Preferences > Resources
# Aumentar Memory (ej: 4GB → 6GB)
# Aumentar Swap
# Reiniciar Docker
```

### Problema: Git + Docker en M1/M2 Macs

```bash
# Si tienes Mac con chip M1/M2 y ves errores raros:
# Agregar a .env:
DOCKER_BUILDKIT=1
BUILDKIT_PROGRESS=plain

export DOCKER_BUILDKIT=1
docker-compose up -d
```

## Performance en macOS

### Optimizaciones

1. **Aumentar recursos de Docker:**
   - Docker > Preferences > Resources
   - CPU Limit: 4 CPUs mínimo
   - Memory: 6GB mínimo

2. **Usar SSD para volúmenes:**
   - Los volúmenes locales serán más rápidos
   - Evitar carpetas sincronizadas (Dropbox, iCloud)

3. **Limpiar periodicamente:**
   ```bash
   docker system prune -a
   ```

## Testing en macOS

```bash
# Verificar conectividad de servicios
docker-compose exec monitoring ping mlflow
docker-compose exec monitoring ping evidently

# Probar endpoints
curl http://localhost:5000
curl http://localhost:8000

# Ver tamaño de volúmenes
du -sh mlflow/mlflow_data
du -sh evidently-service/workspace
```

## Backups en macOS

```bash
# Hacer backup de experimentos
mkdir -p ~/MLops_Backups
cp -r mlflow/mlflow_data ~/MLops_Backups/

# Restaurar
cp -r ~/MLops_Backups/mlflow_data ./mlflow/
```

## Desinstalación Limpia

```bash
# Detener y eliminar todo
docker-compose down -v

# Eliminar imágenes
docker rmi $(docker images -q)

# Eliminar volúmenes huérfanos
docker volume prune

# Limpiar todo
docker system prune -a --volumes
```

---

¡Listo para macOS! 🍎

```bash
cd /Users/pablo/Desktop/MLops/clase-3
docker-compose up -d
docker-compose exec monitoring python train_and_monitor.py
open http://localhost:5000
```

