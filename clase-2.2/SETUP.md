# Setup Inicial - Clase 2.2

**Guía de instalación de Docker y primeros pasos.**

---

## 🔧 Instalar Docker

### macOS

1. **Descargar Docker Desktop:**
   - Ir a: https://www.docker.com/products/docker-desktop
   - Seleccionar tu arquitectura:
     - **Apple Silicon (M1/M2/M3):** Descargar versión ARM64
     - **Intel:** Descargar versión Intel

2. **Instalar:**
   - Descargar archivo `.dmg`
   - Hacer doble click
   - Arrastrar "Docker.app" a Applications
   - Esperar a que se instale

3. **Abrir Docker Desktop:**
   - Buscar "Docker" en Spotlight
   - Hacer click en "Docker.app"
   - Podría pedir contraseña (ingresa tu contraseña de Mac)
   - Esperar a que aparezca el ícono en la barra superior

4. **Verificar instalación:**
   ```bash
   docker --version
   docker run hello-world
   ```

---

### Windows

1. **Descargar Docker Desktop:**
   - Ir a: https://www.docker.com/products/docker-desktop
   - Descargar versión Windows
   - Ejecutar instalador

2. **Instalar:**
   - Doble click en `Docker Desktop Installer.exe`
   - Seguir asistente
   - Reiniciar la computadora si lo pide

3. **Abrir Docker Desktop:**
   - Búsqueda: "Docker Desktop"
   - Hacer doble click
   - Esperar a que aparezca el ícono en la bandeja

4. **Verificar instalación:**
   - Abrir **Git Bash** (https://gitforwindows.org/ si no lo tienes)
   - Ejecutar:
   ```bash
   docker --version
   docker run hello-world
   ```

---

### Linux (Ubuntu/Debian)

```bash
# Instalar Docker
sudo apt-get update
sudo apt-get install docker.io

# Agregar usuario al grupo docker (sin necesidad de sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalación
docker --version
docker run hello-world
```

---

## ⚡ Quick Start (5 minutos)

Una vez que Docker está instalado:

### 1. Navegar a la carpeta

```bash
cd ~/Desktop/MLops/clase-2.2
```

### 2. Opción A: Usar script automático (Recomendado)

```bash
bash scripts/quick-start.sh
```

Este script:
- ✅ Detecta tu SO y arquitectura
- ✅ Construye la imagen con parámetros correctos
- ✅ Ejecuta el contenedor automáticamente

### 2. Opción B: Comandos manuales

**Si tienes Apple Silicon (M1/M2/M3):**
```bash
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

**Si tienes Intel o Linux:**
```bash
docker build -t demo-ml-clase22:local .
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

### 3. Esperar a que se complete

Verás output que incluye:
```
✅ Entrenamientos completados
✅ MLflow UI iniciado
✅ Servicios iniciados

📋 Acceso a servicios:
  • MLflow UI: http://localhost:5000
  • Model Serving: http://localhost:9000
```

### 4. Abrir navegador

- **MLflow UI:** http://localhost:5000
- **Hacer predicción (otra terminal):**
  ```bash
  curl -X POST http://localhost:9000/invocations \
    -H 'Content-Type: application/json' \
    -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
  ```

---

## 🐛 Verificaciones

### Docker está instalado correctamente

```bash
docker --version
# Salida esperada: Docker version XX.XX.XX, build ...
```

### Docker puede ejecutar contenedores

```bash
docker run hello-world
# Salida esperada: "Hello from Docker!"
```

### Docker Desktop está corriendo

```bash
docker ps
# Si funciona, Docker Desktop está activo
```

---

## ⚠️ Troubleshooting Inicial

### ❌ "docker: command not found"

**Solución:**
- Verificar que Docker Desktop está abierto
- En macOS: Buscar "Docker" en Spotlight y abrir
- En Windows: Buscar "Docker Desktop" en búsqueda

### ❌ "Cannot connect to Docker daemon"

**Solución:**
- Abrir Docker Desktop (aparecerá un ícono en la barra)
- Esperar a que el estado indique "Docker is running"

### ❌ "docker run hello-world" cuelga

**Solución:**
- Presionar Ctrl+C
- Reiniciar Docker Desktop
- Esperar 30 segundos
- Intentar de nuevo

### ❌ En Windows: "WSL not installed"

**Solución:**
- Docker Desktop necesita WSL 2
- Abrir PowerShell como administrador y ejecutar:
  ```powershell
  wsl --install
  ```
- Reiniciar computadora
- Abrir Docker Desktop de nuevo

---

## 📋 Próximos Pasos

1. **Completar Quick Start:** `bash scripts/quick-start.sh`
2. **Leer ONBOARDING.md:** Explicación paso a paso
3. **Explorar MLflow UI:** http://localhost:5000
4. **Hacer predicciones:** Usando curl

---

## 🎯 Verificación Final

Todos estos comandos deben funcionar:

```bash
# 1. Docker está corriendo
docker ps

# 2. Imagen está construida
docker images | grep demo-ml-clase22

# 3. Puedes acceder a MLflow UI (en navegador)
http://localhost:5000

# 4. Puedes hacer predicciones
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'
```

---

**¡Setup completado!** 🎉

Ahora puedes continuar con **ONBOARDING.md** para una guía paso a paso.

