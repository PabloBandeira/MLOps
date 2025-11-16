# Onboarding - Clase 2.2

**Full Docker MLflow: Entrenamiento + UI + Serving Todo en Uno**

Guía paso a paso para ejecutar la clase 2.2 completamente en Docker.

---

## 🎯 ¿Qué vas a lograr?

Al final de este onboarding podrás:

- ✅ Construir imagen Docker con Python 3.11
- ✅ Ejecutar entrenamientos automáticos en Docker
- ✅ Acceder a MLflow UI en `http://localhost:5000`
- ✅ Servir modelo via API REST en `http://localhost:9000`
- ✅ Hacer predicciones desde terminal

**Tiempo estimado:** 10-15 minutos

---

## 📋 Requisitos Previos

### Instalar Docker

**macOS:**
1. Descargar: https://www.docker.com/products/docker-desktop
2. Instalar y abrir Docker Desktop
3. Verificar: `docker --version`

**Windows:**
1. Descargar: https://www.docker.com/products/docker-desktop
2. Instalar y abrir Docker Desktop
3. Abrir Git Bash o PowerShell
4. Verificar: `docker --version`

**Linux:**
```bash
sudo apt-get install docker.io
sudo usermod -aG docker $USER
docker --version
```

```bash
# Navegar a la carpeta del proyecto
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-2.2

# Crear y activar venv
py -3.11 -m venv .venv || python -m venv .venv
source .venv/Scripts/activate

# Verificar activación (debe mostrar ruta a .venv)
which python

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt


#Sin files guardados
bash scripts/quick-start.sh

#Con files guardados
docker run -p 5000:5000 -p 9000:9000 -v "$PWD:/app" --rm demo-ml-clase22:local


curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'

```

### Verificar que Docker funciona

```bash
docker run hello-world
```

Debería mostrar:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

## 🚀 Setup Rápido (5 minutos)

### 1. Navegar a la carpeta

**macOS/Linux:**
```bash
cd ~/Desktop/MLops/clase-2.2
```

**Windows (Git Bash):**
```bash
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-2.2
```

### 2. Construir imagen Docker

**macOS Apple Silicon (M1/M2/M3):**
```bash
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .
```

**macOS/Windows Intel o Linux:**
```bash
docker build -t demo-ml-clase22:local .
```

**Salida esperada:**
```
[+] Building 45s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 ...
 => => naming to docker.io/library/demo-ml-clase22:local
```

### 3. Verificar que la imagen se creó

```bash
docker images | grep demo-ml-clase22
```

Debería mostrar:
```
demo-ml-clase22   local   abc123def456   2 minutes ago   1.5GB
```

---

## ▶️ Ejecutar (Paso más importante)

### Run contenedor (TODO se inicia automáticamente)

```bash
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

**¿Qué sucede?**

1. ✅ Se ejecutan 3 entrenamientos (3 experimentos)
2. ✅ Se inicia MLflow UI en background (puerto 5000)
3. ✅ Se inicia Model Serving en background (puerto 9000)

**Salida esperada (primeros 30 segundos):**

```
==========================================
Iniciando Clase 2.2 - Full Docker Setup
==========================================

📊 Paso 1: Ejecutando experimentos...
==========================================
Ejecutando experimentos de MLflow en Docker...

Experimento 1: n_estimators=50, max_depth=5
Run ID: abc123def456...
acc: 0.9333
...

Experimento 2: n_estimators=100, max_depth=10
Run ID: def456ghi789...
acc: 0.9667
...

Experimento 3: n_estimators=150, max_depth=None
Run ID: ghi789jkl012...
acc: 0.9667
...

✅ Entrenamientos completados

🎯 Paso 2: Levantando MLflow UI en puerto 5000...
==========================================
✅ MLflow UI iniciado (PID: 123)

🚀 Paso 3: Levantando Model Serving en puerto 9000...
==========================================
✅ Último Run ID: ghi789jkl012...
✅ Servicios iniciados
==========================================

📋 Acceso a servicios:
  • MLflow UI: http://localhost:5000
  • Model Serving: http://localhost:9000
  
⏹️  Para detener los servicios, presiona Ctrl+C
```

✅ **Ahora los servicios están corriendo. NO CIERRES ESTA TERMINAL.**

---

## 🎨 Paso 1: Visualizar Experimentos en MLflow UI

### Abrir navegador

En tu navegador, ve a:
```
http://localhost:5000
```

### ¿Qué ver?

1. **Panel izquierdo:**
   - Experimento: "iris-classification"
   - 3 Runs listados

2. **Columnas de experimentos:**
   - Run 1: `n_estimators=50, max_depth=5` → `acc: 0.9333`
   - Run 2: `n_estimators=100, max_depth=10` → `acc: 0.9667`
   - Run 3: `n_estimators=150, max_depth=None` → `acc: 0.9667`

3. **Comparar:**
   - Hacer click en "Runs" → Compare
   - Ver qué configuración da mejor accuracy

---

## 🚀 Paso 2: Hacer Predicción (Inferencia)

### Abrir OTRA terminal (sin cerrar la primera)

**macOS/Linux:**
```bash
# Nueva terminal o tab
cd ~/Desktop/MLops/clase-2.2
```

**Windows (Git Bash):**
```bash
# Nueva ventana de Git Bash
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-2.2
```

### Hacer una predicción (Iris Virginica - grande)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
```

**Salida esperada:**
```json
{"predictions": [2]}
```

✅ **¡Funcionó! El modelo predice clase 2 (Virginica).**

---

## 🧪 Paso 3: Probar Otras Predicciones

### Predicción 2: Iris Setosa (pequeño)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'
```

**Salida:** `{"predictions": [0]}` ✅ Clase 0 (Setosa)

### Predicción 3: Iris Versicolor (medio)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[6.0, 2.7, 5.1, 1.6]]}}'
```

**Salida:** `{"predictions": [1]}` ✅ Clase 1 (Versicolor)

---

## 🛑 Parar los Servicios

Cuando termines, vuelve a la terminal donde corre Docker y presiona:

```
Ctrl + C
```

Verás:
```
^C
Traceback (most recent call last):
  ...
KeyboardInterrupt
(.venv) pablo@MacBook-Pro clase-2.2 %
```

✅ El contenedor se ha detenido correctamente.

---

## 🔍 Debugging: Comandos Útiles

### Si algo sale mal, verifica esto

**¿Docker está corriendo?**
```bash
docker ps
```

Debería mostrar el contenedor en ejecución.

**¿Ver logs del contenedor?**
```bash
docker logs <CONTAINER_ID>
```

**¿Verificar puertos en uso?**
```bash
# macOS/Linux
lsof -i :5000
lsof -i :9000

# Windows (PowerShell)
netstat -ano | findstr :5000
```

**¿Limpiar contenedores antiguos?**
```bash
docker system prune
```

---

## 🐛 Troubleshooting Común

### ❌ "Cannot connect to Docker daemon"

**Solución:** Abre Docker Desktop

```bash
# macOS: Buscar "Docker" y abrir
# Windows: Buscar "Docker Desktop" y hacer doble click
```

### ❌ "port 5000 is already allocated"

**Solución:** Cambiar puertos

```bash
docker run -p 5001:5000 -p 9001:9000 --rm demo-ml-clase22:local

# Luego acceder a:
# http://localhost:5001 (MLflow UI)
# http://localhost:9001 (Model Serving)
```

### ❌ "platform mismatch" en Apple Silicon

**Solución:** Reconstruir con --platform

```bash
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .
docker run --platform=linux/arm64/v8 -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

### ❌ curl: command not found (Windows)

**Solución:** Usar Git Bash o PowerShell

```bash
# Git Bash incluye curl
bash

# O en PowerShell:
Invoke-WebRequest -Uri "http://localhost:9000/invocations" `
  -Method POST `
  -Headers @{"Content-Type" = "application/json"} `
  -Body '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
```

### ❌ No puedo acceder a http://localhost:5000

**Solución:** Esperar 5 segundos y verificar logs

```bash
# Terminal 1: Ver logs
docker logs -f <CONTAINER_ID>

# Buscar: "MLflow UI iniciado"
# Si no ves eso, hay error en los entrenamientos
```

### ❌ Modelo serving no responde

**Solución:** Verificar que el entrenamiento completó

```bash
# En terminal 1 (donde corre Docker), buscar:
# "✓ Experimentos completados"
# "✅ Último Run ID:"

# Si no lo ves, espera más tiempo
```

---

## 📊 Anatomía del Flujo

```
┌─────────────────────────────────────────────────────────┐
│                   DOCKER CONTAINER                       │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │ 1. docker-entrypoint.sh (Script principal)         │ │
│  │    ├─ Ejecuta: train-in-docker.sh                  │ │
│  │    │   ├─ Experimento 1: n_estimators=50          │ │
│  │    │   ├─ Experimento 2: n_estimators=100         │ │
│  │    │   └─ Experimento 3: n_estimators=150         │ │
│  │    │                                                │ │
│  │    ├─ Inicia: mlflow ui --host 0.0.0.0 --port 5000│ │
│  │    │   └─ En background (no bloquea)              │ │
│  │    │                                                │ │
│  │    └─ Inicia: mlflow models serve --port 9000     │ │
│  │        └─ En foreground (espera Ctrl+C)           │ │
│  └────────────────────────────────────────────────────┘ │
│                                                           │
│  Puertos expuestos:                                       │
│  5000 ──→ MLflow UI                                       │
│  9000 ──→ Model Serving API                              │
└─────────────────────────────────────────────────────────┘
     ↓                    ↓
  localhost:5000     localhost:9000
  (Tu navegador)      (curl/HTTP)
```

---

## 📁 Estructura Interna

```
Dentro del contenedor:
/app/
├── src/
│   ├── train.py
│   └── train_mlflow.py        ← Script de entrenamiento
├── tests/
├── scripts/
│   ├── docker-entrypoint.sh   ← Script que se ejecuta al iniciar
│   └── train-in-docker.sh     ← Script de experimentos
├── mlruns/                    ← Directorio de MLflow
│   └── 612217226539791719/    ← Experiment ID
│       ├── run1/              ← Experimento 1
│       ├── run2/              ← Experimento 2
│       └── run3/              ← Experimento 3
└── requirements.txt
```

---

## 🎓 ¿Qué Aprendiste?

✅ Contenedores Docker encapsulan ambientes  
✅ Mapeo de puertos conecta Docker con tu máquina  
✅ MLflow UI permite visualizar experimentos  
✅ MLflow Model Serving expone modelos via API  
✅ Todo integrado en UN contenedor = reproducibilidad  

---

## 🔄 Próximos Pasos

1. **Explorar MLflow UI:**
   - Comparar experimentos
   - Ver parámetros vs métricas
   - Descargar artefactos

2. **Modificar entrenamientos:**
   - Agregar más experimentos en `train-in-docker.sh`
   - Cambiar hiperparámetros
   - Probar otros modelos

3. **Persistencia de datos:**
   - Correr con volumen: `docker run -v "$PWD:/app" ...`
   - Los datos se guardan localmente

4. **Deployar a producción:**
   - Usar Docker Compose para orquestar
   - Agregar base de datos
   - Integrar CI/CD

---

## 📚 Recursos

- MLflow Docs: https://mlflow.org/docs/
- Docker Docs: https://docs.docker.com/
- Iris Dataset: https://en.wikipedia.org/wiki/Iris_flower_data_set

---

## 💬 Preguntas Frecuentes

**P: ¿Por qué todo está en Docker?**  
R: Reproducibilidad. Cualquier estudiante con Docker obtiene el mismo ambiente exacto.

**P: ¿Puedo cambiar el puerto 5000?**  
R: Sí. Edita `docker-entrypoint.sh` línea `mlflow ui --port 5001`

**P: ¿Dónde se guardan los datos?**  
R: En `mlruns/` dentro del contenedor. Con `-v`, se guarda en tu máquina.

**P: ¿Puedo usar Windows?**  
R: Sí, con Docker Desktop + Git Bash o PowerShell.

**P: ¿Funciona en Apple Silicon?**  
R: Sí, usa `--platform=linux/arm64/v8` en build y run.

---

**¡Felicidades, completaste el onboarding!** 🎉

Ahora entiendes:
- Cómo construir imágenes Docker
- Cómo mapear puertos
- Cómo ejecutar servicios en background
- Cómo hacer inferencia via API

**¡Listo para la siguiente clase!** 🚀

