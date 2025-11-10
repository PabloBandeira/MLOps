# Clase 2.2 - Full Docker MLflow (Entrenamiento + UI + Serving)

**Versión completamente Dockerizada de MLflow** con entrenamientos, UI, y model serving todo en un contenedor.

---

## 🎯 Objetivo

Que los estudiantes ejecuten **TODO desde Docker**:
- ✅ Entrenar modelos con MLflow
- ✅ Visualizar experimentos en MLflow UI (puerto 5000)
- ✅ Servir modelo con API REST (puerto 9000)
- ✅ Hacer predicciones desde terminal

---

## 📦 Diferencias vs Clase 2

| Aspecto | Clase 2 | Clase 2.2 |
|--------|--------|----------|
| Entrenamiento | Local | **Docker** |
| MLflow UI | Local en terminal | **Docker en background** |
| Model Serving | Local en terminal | **Docker en background** |
| Puertos expuestos | Manual | **Automático (5000 + 9000)** |
| Complejidad | Media | **Simplificada para docker** |
| Experiencia | 3+ terminales | **1 terminal (todo automático)** |

---

## 🚀 Uso Rápido

### 1. Build imagen Docker

**Mac (Apple Silicon):**
```bash
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .
```

**Mac/Linux (Intel):**
```bash
docker build -t demo-ml-clase22:local .
```

### 2. Run contenedor (Todo se ejecuta automáticamente)

```bash
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

Esto ejecuta:
1. 📊 Entrenamientos (3 experimentos)
2. 🎯 MLflow UI en background (puerto 5000)
3. 🚀 Model Serving en background (puerto 9000)

### 3. Acceder a servicios

**MLflow UI (ver experimentos):**
```
http://localhost:5000
```

**Hacer predicción (desde OTRA terminal):**
```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
```

**Respuesta esperada:**
```json
{"predictions": [2]}
```

---

## 🔄 Estructura del Flujo

```
┌─ DOCKER CONTAINER ─────────────────────────────┐
│                                                   │
│  1️⃣  docker-entrypoint.sh                       │
│      ├─ train-in-docker.sh (3 experimentos)    │
│      ├─ mlflow ui --host 0.0.0.0 --port 5000   │ ← Accesible localmente
│      └─ mlflow models serve --port 9000         │ ← Accesible localmente
│                                                   │
│  Mapeo de puertos:                              │
│  Docker:5000 → localhost:5000                   │
│  Docker:9000 → localhost:9000                   │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## 📋 Comandos Útiles

### Construir imagen

```bash
# Apple Silicon
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .

# Intel
docker build -t demo-ml-clase22:local .
```

### Ejecutar (modo normal)

```bash
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

### Ejecutar con volumen (persistencia datos)

```bash
# Los datos de mlruns/ se guardan localmente
docker run -p 5000:5000 -p 9000:9000 -v "$PWD:/app" --rm demo-ml-clase22:local
```

### Ejecutar en background

```bash
docker run -d -p 5000:5000 -p 9000:9000 --rm --name mlflow-clase22 demo-ml-clase22:local

# Ver logs
docker logs -f mlflow-clase22

# Detener
docker stop mlflow-clase22
```

### Ejecutar bash interactivo (debugging)

```bash
docker run -it -p 5000:5000 -p 9000:9000 -v "$PWD:/app" --rm demo-ml-clase22:local bash
```

---

## 🧪 Pruebas de Predicción

### Clase 0 (Setosa - flores pequeñas)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'
```

**Respuesta:** `{"predictions": [0]}`

### Clase 1 (Versicolor - tamaño medio)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[6.0, 2.7, 5.1, 1.6]]}}'
```

**Respuesta:** `{"predictions": [1]}`

### Clase 2 (Virginica - flores grandes)

```bash
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
```

**Respuesta:** `{"predictions": [2]}`

---

## 📊 Monitoreo de Servicios

### Ver si el contenedor está corriendo

```bash
docker ps | grep demo-ml-clase22
```

### Ver logs en tiempo real

```bash
docker logs -f <CONTAINER_ID>
```

### Detener el contenedor

```bash
docker stop <CONTAINER_ID>
```

---

## ⚠️ Troubleshooting

### Error: "port is already allocated"

```bash
# Puerto 5000 o 9000 ya en uso
# Opción 1: Usar otros puertos
docker run -p 5001:5000 -p 9001:9000 --rm demo-ml-clase22:local

# Opción 2: Ver qué está usando el puerto
lsof -i :5000
lsof -i :9000

# Opción 3: Matar el proceso
kill -9 <PID>
```

### Error: "platform mismatch" en Apple Silicon

```bash
# Agregar --platform
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .
docker run --platform=linux/arm64/v8 -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
```

### No puedo acceder a http://localhost:5000

```bash
# Verificar que el contenedor está corriendo
docker ps

# Ver logs para errores
docker logs <CONTAINER_ID>

# Esperar a que se inicien los servicios (3-5 segundos)
```

### curl no funciona en Windows

```bash
# Usar Git Bash o descargar curl desde: https://curl.se/windows/
# O desde PowerShell:
Invoke-WebRequest -Uri "http://localhost:9000/invocations" ...
```

---

## 🎓 Flujo de Aprendizaje Recomendado

1. **Build imagen:**
   ```bash
   docker build -t demo-ml-clase22:local .
   ```

2. **Run contenedor:**
   ```bash
   docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local
   ```

3. **Abrir MLflow UI:**
   - Ir a: http://localhost:5000
   - Ver los 3 experimentos con diferentes hiperparámetros

4. **Comparar experimentos:**
   - Ver cuál tiene mejor accuracy
   - Notar diferencias entre configuraciones

5. **Hacer predicciones:**
   - Abrir otra terminal
   - Ejecutar comandos curl con diferentes valores
   - Observar las predicciones

6. **Entender el flujo:**
   - Todo corre en un contenedor
   - Los puertos están mapeados localmente
   - El modelo se entrena y sirve automáticamente

---

## 📁 Estructura de Archivos

```
clase-2.2/
├── Dockerfile                 # Imagen Docker con Python 3.11
├── requirements.txt           # Dependencias (mlflow, sklearn, etc)
├── src/
│   └── train_mlflow.py        # Script de entrenamiento
├── tests/
│   ├── test_train.py
│   └── test_train_mlflow.py
└── scripts/
    ├── docker-entrypoint.sh   # Script principal (dentro de Docker)
    └── train-in-docker.sh     # Script de experimentos
```

---

## 🔧 Personalización

### Cambiar puerto 5000 o 9000

**En docker-entrypoint.sh:**
```bash
mlflow ui --host 0.0.0.0 --port 5001  # Cambiar 5001
mlflow models serve -m "$MODEL_URI" -p 9001 --host 0.0.0.0  # Cambiar 9001
```

**Al ejecutar:**
```bash
docker run -p 5001:5001 -p 9001:9001 --rm demo-ml-clase22:local
```

### Agregar más experimentos

**En train-in-docker.sh, agregar:**
```bash
echo "Experimento 4: custom_params"
python -c "
from src.train_mlflow import train_model
train_model(n_estimators=200, max_depth=15, random_state=42)
"
```

### Cambiar modelo entrenado

**En src/train_mlflow.py, cambiar:**
```python
# De RandomForestClassifier a otro modelo
from sklearn.svm import SVC
model = SVC()
```

---

## 🎯 Objetivos de Aprendizaje

✅ Entender contenedores Docker  
✅ Manejar múltiples servicios en un contenedor  
✅ Usar MLflow desde Docker  
✅ Acceder a servicios desde el host  
✅ Hacer predicciones via API  
✅ Debugging de contenedores  

---

## 📞 Soporte

Si hay problemas:
1. Verificar que Docker Desktop está corriendo
2. Ver logs: `docker logs <CONTAINER_ID>`
3. Verificar puertos: `docker ps`
4. Limpiar contenedores: `docker system prune`

---

**¡Listo para empezar!** 🚀

