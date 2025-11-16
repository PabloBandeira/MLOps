# 👨‍🏫 Guía del Instructor - Clase 2.2

**Cómo usar este material con estudiantes de la maestría**

---

## 🎯 Objetivo de la Clase

Los estudiantes entenderán:
- Cómo containerizar aplicaciones con Docker
- Cómo orquestar múltiples servicios (MLflow UI + Model Serving)
- Cómo hacer que todo sea reproducible
- Cómo servir modelos en producción

---

## 📋 Estructura de la Clase (60 minutos)

### Parte 1: Setup (10 minutos)

**Antes de la clase:**
- ✅ Asegúrate que Docker Desktop funcione en tu máquina
- ✅ Prueba correr: `bash scripts/quick-start.sh`
- ✅ Verifica que MLflow UI y Model Serving inicien sin errores

**Durante la clase:**
1. Pedir que todos instalen Docker Desktop
2. Verificar conexión de internet
3. Explicar qué es Docker (container = máquina virtual ultra ligera)

**Comando a pasar:**
```bash
bash scripts/quick-start.sh
```

---

### Parte 2: Exploración (15 minutos)

**Lo que cada estudiante hará:**

1. **Abrir MLflow UI:**
   - http://localhost:5000
   - Ver 3 experimentos
   - Comparar parámetros vs métricas
   - Identificar mejor model

2. **Entender qué es cada cosa:**
   - Parámetros: Configuración del modelo (n_estimators, max_depth)
   - Métricas: Resultados (accuracy, f1, precision, recall)
   - Artefactos: El modelo guardado

3. **Preguntas para discutir:**
   - ¿Por qué el experimento 3 tiene la misma accuracy que el 2?
   - ¿Cuál usarías en producción?
   - ¿Cuál es más rápido de entrenar?

---

### Parte 3: Predicciones (15 minutos)

**Demostraré:**
```bash
# Hacer predicción desde terminal
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'

# Respuesta:
{"predictions": [2]}
```

**Explicar:**
- El modelo está servido en puerto 9000
- Recibe JSON, devuelve predicción
- Esto es lo que se usa en producción
- Cualquier aplicación puede hacer requests HTTP

**Actividad:**
- Cada estudiante hace al menos 2 predicciones
- Con valores diferentes
- Verifica que la predicción tenga sentido

---

### Parte 4: Explicar la Arquitectura (15 minutos)

**Dibujar en pizarra/pantalla:**

```
┌─ DOCKER CONTAINER ──────────────────────┐
│                                          │
│  1. Entrenamientos (3 experimentos)     │
│     └─ Guarda modelos en mlruns/       │
│                                          │
│  2. MLflow UI (puerto 5000)             │
│     └─ Accesible desde tu navegador    │
│                                          │
│  3. Model Serving (puerto 9000)         │
│     └─ API REST para predicciones      │
│                                          │
└──────────────────────────────────────────┘
     ↓              ↓
localhost:5000   localhost:9000
(Navegador)      (curl/HTTP)
```

**Puntos clave:**

1. **¿Por qué Docker?**
   - Reproducibilidad: Mismo ambiente para todos
   - Aislamiento: No afecta otras cosas
   - Portabilidad: Funciona en cualquier máquina

2. **¿Por qué todo junto?**
   - Entrenamientos → MLflow (tracking)
   - MLflow → UI (visualización)
   - Modelo → Serving (API)
   - Todo coordinado automáticamente

3. **¿Cómo se ejecuta?**
   - `docker-entrypoint.sh` orquesta todo
   - Inicia entrenamientos primero
   - Luego levanta servicios en background
   - El último servicio se queda en foreground

---

### Parte 5: Preguntas y Debate (5 minutos)

**Preguntas para estimular:**

1. "¿Qué sucedería si apagamos Docker ahora? ¿Dónde están los datos?"
   - Respuesta: Si corriste sin `-v`, se pierden. Con `-v`, están en tu máquina.

2. "¿Cómo serviríamos esto en producción?"
   - Respuesta: Kubernetes, ECS, Cloud Run, etc.

3. "¿Qué pasaría si agregamos más modelos?"
   - Respuesta: Más experimentos, puede haber conflicto de puertos

4. "¿Cómo automatizamos los entrenamientos?"
   - Respuesta: CI/CD, cron jobs, triggers

---

## 📚 Materiales Proporcionados

### Para Estudiantes

| Archivo | Propósito |
|---------|-----------|
| **INDEX.md** | Punto de entrada, navegación |
| **SETUP.md** | Instalación de Docker |
| **ONBOARDING.md** | Guía paso a paso completa |
| **README.md** | Referencia técnica y comandos |

### Para Instructores (Este archivo)

| Archivo | Propósito |
|---------|-----------|
| **GUIA_DEL_INSTRUCTOR.md** | Plan de clase |
| **Dockerfile** | Especificación de imagen |
| **scripts/docker-entrypoint.sh** | Orquestación |

---

## 🛠️ Preparación Antes de la Clase

### Checklist

- [ ] Instalar Docker Desktop en tu máquina
- [ ] Ejecutar `bash scripts/quick-start.sh`
- [ ] Verificar http://localhost:5000 funciona
- [ ] Hacer una predicción de prueba
- [ ] Probar en Apple Silicon (si lo tienes)
- [ ] Probar en Windows (si tienes VM o laptop Windows)
- [ ] Verificar velocidad de internet (descarga de imagen ~1-2 GB)
- [ ] Preparar examples de predicción

### Archivos a Revisar Antes

```bash
# Entender la arquitectura
cat Dockerfile
cat scripts/docker-entrypoint.sh
cat scripts/train-in-docker.sh

# Ver requisitos
cat requirements.txt
cat src/train_mlflow.py
```

---

## 🎓 Conceptos Clave a Enseñar

### 1. Docker Basics

**Explicar:**
- Contenedor = máquina virtual ligera
- Imagen = plantilla, contenedor = instancia
- `docker build` = crear imagen
- `docker run` = ejecutar contenedor
- Puertos = mapeo de puertos host ↔ container

**Ejemplo:**
```
docker run -p 5000:5000 ...
↑ puerto 5000 en tu máquina
           ↑ puerto 5000 en el container
```

### 2. MLflow Tracking

**Explicar:**
- Experimento = conjunto de runs
- Run = ejecución singular
- Parámetros = inputs al modelo
- Métricas = outputs (performance)
- Artefactos = modelo guardado

### 3. MLflow Serving

**Explicar:**
- `mlflow models serve` expone API REST
- El modelo recibe JSON, devuelve predicción
- Esto es lo que se usa en producción
- Escalable (puede servir miles de requests)

### 4. Reproducibilidad

**Explicar:**
- Docker garantiza: mismo SO, mismo Python, mismas librerías
- Estudiante A en macOS = Estudiante B en Windows
- Sin "funciona en mi máquina pero no en producción"

---

## 🎯 Objetivos de Aprendizaje

Al final, estudiante debe poder:

✅ **Explicar:** Qué es un contenedor Docker  
✅ **Usar:** `docker build` y `docker run`  
✅ **Navegar:** MLflow UI  
✅ **Hacer:** Predicciones via curl  
✅ **Entender:** Por qué esto es importante para producción  

---

## 🔧 Troubleshooting Común en Clase

### Problema: "Mi imagen tarda mucho en descargar"

**Solución:**
- Es normal en primer run (~1-2 GB)
- Mientras espera, explicar Docker fundamentals
- Segundo run es casi instantáneo

### Problema: "Estudiante A en macOS tarda más que B en Windows"

**Solución:**
- Depende de specs de máquina
- Mostrar que mismo código, similar performance
- Es el punto de Docker!

### Problema: "No puedo acceder a localhost:5000"

**Solución:**
- Verificar que `docker ps` muestra el container
- Ver logs: `docker logs <CONTAINER_ID>`
- Esperar 10 segundos a que los servicios inicien

### Problema: "curl no funciona en mi Windows"

**Solución:**
- Usar Git Bash (incluye curl)
- O PowerShell con `Invoke-WebRequest`
- O proporcionarles archivo .bat

---

## 📊 Métricas de Éxito

**Saber si la clase fue exitosa:**

✅ Todos los estudiantes logran:
- [ ] Instalar Docker
- [ ] Construir la imagen
- [ ] Ejecutar el contenedor
- [ ] Acceder a MLflow UI
- [ ] Hacer una predicción

✅ Entienden conceptos de:
- [ ] Docker y containers
- [ ] MLflow tracking y serving
- [ ] APIs REST
- [ ] Reproducibilidad

---

## 📝 Variaciones para Diferentes Niveles

### Nivel 1: Principiantes
- Solo usar `bash scripts/quick-start.sh`
- Explorar MLflow UI
- Hacer predicciones
- No tocar código

### Nivel 2: Intermedio
- Explicar qué hace cada script
- Mostrar Dockerfile
- Modificar hiperparámetros en `train-in-docker.sh`
- Agregar más experimentos

### Nivel 3: Avanzado
- Entender flujo completo
- Modificar `docker-entrypoint.sh`
- Agregar nuevos modelos
- Deployar con Docker Compose
- Integrar con CI/CD

---

## 🎬 Ejemplo de Clase (Guion)

### Introducción (5 min)

"Hoy vamos a ver cómo Docker revoluciona el ML. El problema típico es: 'Funciona en mi máquina pero no en producción'. Docker lo soluciona."

### Demo (5 min)

```bash
# Mostrar que Docker está vacío
docker ps

# Correr
bash scripts/quick-start.sh

# Mientras se ejecuta, explicar qué pasa en background
```

### Exploración (15 min)

"Abran http://localhost:5000. Ven 3 experimentos. ¿Qué significan estos números?"

(Discutir parámetros, métricas, diferencias)

### Predicciones (10 min)

"Ahora vamos a hacer predicciones. Es como pedirle al modelo que clasifique una flor nueva."

```bash
curl -X POST http://localhost:9000/invocations ...
```

(Mostrar diferentes ejemplos)

### Explicación Técnica (15 min)

"Detrás de escenas, esto es lo que pasó..."

(Dibujar arquitectura)

### Preguntas y Cierre (10 min)

"¿Preguntas?"
"¿Cómo creen que esto se usa en Google, Netflix, etc?"

---

## 🚀 Después de la Clase

**Enviar a estudiantes:**
1. INDEX.md (como referencia)
2. Comando para reproducir en casa: `bash scripts/quick-start.sh`
3. Link a recursos Docker/MLflow

**Sugerencias para tareas:**
1. Agregar un 4to experimento
2. Cambiar hiperparámetros y comparar
3. Documentar el flujo en README propio
4. Hacer predicciones y documentar

---

## 📞 Soporte

**Si tienes dudas sobre:**
- Docker: Ver SETUP.md o usar `docker --help`
- MLflow: Ver README.md o MLflow official docs
- Scripts: Revisar comentarios en `docker-entrypoint.sh`

---

## 📅 Timing Sugerido

| Tiempo | Actividad | Duración |
|--------|-----------|----------|
| 0:00 | Introducción | 5 min |
| 0:05 | Instalación/Download Docker image | 5 min |
| 0:10 | Ejecutar `quick-start.sh` | 5 min |
| 0:15 | Explorar MLflow UI | 10 min |
| 0:25 | Hacer predicciones | 10 min |
| 0:35 | Explicar arquitectura | 10 min |
| 0:45 | Debugging/Troubleshooting | 10 min |
| 0:55 | Preguntas y cierre | 5 min |

---

**¡Buena suerte con la clase!** 🎉

Cualquier pregunta, revisar los archivos .md o contactar.

