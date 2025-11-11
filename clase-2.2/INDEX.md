# 📚 Clase 2.2 - Índice de Documentación

**Full Docker MLflow: Entrenamientos + UI + Serving**

---

## 🚀 Comienza Aquí

### Para Alumnos NUEVOS (Sin Docker)

1. **[SETUP.md](./SETUP.md)** ← Empieza aquí
   - Instalar Docker Desktop
   - Verificaciones iniciales
   - Quick Start de 5 minutos

2. **[ONBOARDING.md](./ONBOARDING.md)** ← Guía completa paso a paso
   - Construcción de imagen
   - Ejecución de contenedor
   - Visualización en MLflow UI
   - Pruebas de predicción
   - Debugging y troubleshooting

3. **[README.md](./README.md)** ← Referencia técnica
   - Comandos útiles
   - Estructura de archivos
   - Personalización

---

## 📂 Estructura de Archivos

```
clase-2.2/
├── 📄 INDEX.md                    ← TÚ ESTÁS AQUÍ
├── 📄 SETUP.md                    ← Instalación inicial
├── 📄 ONBOARDING.md               ← Guía paso a paso
├── 📄 README.md                   ← Referencia técnica
├── 🐳 Dockerfile                  ← Especificación de imagen
├── 📦 requirements.txt            ← Dependencias Python
├── 📝 docker-compose.yml          ← (Opcional) Orquestación
├── src/
│   ├── train.py                   ← Entrenamiento básico
│   └── train_mlflow.py            ← Con MLflow tracking
├── tests/
│   ├── test_train.py
│   └── test_train_mlflow.py
└── scripts/
    ├── quick-start.sh             ← AUTO SETUP (recomendado)
    ├── docker-entrypoint.sh       ← Script principal de Docker
    └── train-in-docker.sh         ← Experimentos dentro Docker
```

---

## 🎓 Rutas de Aprendizaje

### Ruta 1: Completa (Recomendada)

```
1. SETUP.md
   ↓
2. ONBOARDING.md (Paso 1: MLflow UI)
   ↓
3. ONBOARDING.md (Paso 2: Predicciones)
   ↓
4. ONBOARDING.md (Paso 3: Otras predicciones)
   ↓
5. README.md (Referencia)
```

### Ruta 2: Rápida (5 minutos)

```
1. SETUP.md (Solo instalación)
   ↓
2. bash scripts/quick-start.sh
   ↓
3. Explorar http://localhost:5000
```

### Ruta 3: Técnica (Para instructores)

```
1. Dockerfile (Entender estructura)
   ↓
2. docker-compose.yml (Orquestación)
   ↓
3. scripts/docker-entrypoint.sh (Flujo)
   ↓
4. README.md (Personalización)
```

---

## 🎯 Objetivos por Documento

### SETUP.md
- ✅ Instalar Docker Desktop
- ✅ Verificar instalación
- ✅ Ejecutar hello-world
- ✅ Troubleshooting de instalación

### ONBOARDING.md
- ✅ Construir imagen Docker
- ✅ Ejecutar contenedor
- ✅ Acceder a MLflow UI
- ✅ Hacer predicciones
- ✅ Debugging de servicios

### README.md
- ✅ Referencia de comandos
- ✅ Estructura de archivos
- ✅ Personalización del proyecto
- ✅ Troubleshooting avanzado

---

## ⚡ Comandos Más Usados

### Instalación

```bash
# Automático (recomendado)
bash scripts/quick-start.sh

# Manual - Apple Silicon
docker build --platform=linux/arm64/v8 -t demo-ml-clase22:local .

# Manual - Intel/Linux
docker build -t demo-ml-clase22:local .
```

### Ejecución

```bash
# Run normal
docker run -p 5000:5000 -p 9000:9000 --rm demo-ml-clase22:local

# Con volumen (persistencia)
docker run -p 5000:5000 -p 9000:9000 -v "$PWD:/app" --rm demo-ml-clase22:local

# En background
docker run -d -p 5000:5000 -p 9000:9000 --name mlflow22 demo-ml-clase22:local
```

### Debugging

```bash
# Ver logs
docker logs -f <CONTAINER_ID>

# Ejecutar bash
docker run -it -p 5000:5000 -p 9000:9000 -v "$PWD:/app" demo-ml-clase22:local bash

# Ver contenedores
docker ps
docker ps -a
```

### Predicciones

```bash
# Clase 0 (Setosa)
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'

# Clase 1 (Versicolor)
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[6.0, 2.7, 5.1, 1.6]]}}'

# Clase 2 (Virginica)
curl -X POST http://localhost:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[7.7, 3.8, 6.7, 2.2]]}}'
```

---

## 🔍 Búsqueda Rápida

**¿Cómo instalo Docker?**  
→ [SETUP.md](./SETUP.md)

**¿Cómo construyo la imagen?**  
→ [ONBOARDING.md - Paso 2](./ONBOARDING.md#️--paso-2-construir-imagen-docker)

**¿Cómo accedo a MLflow UI?**  
→ [ONBOARDING.md - Paso 1: Visualizar](./ONBOARDING.md#-paso-1-visualizar-experimentos-en-mlflow-ui)

**¿Cómo hago predicciones?**  
→ [ONBOARDING.md - Paso 2: Predicción](./ONBOARDING.md#-paso-2-hacer-predicción-inferencia)

**¿Qué comandos hay?**  
→ [README.md - Comandos Útiles](./README.md#-comandos-útiles)

**¿Cómo debugueo?**  
→ [README.md - Troubleshooting](./README.md#️-troubleshooting) o [ONBOARDING.md - Debugging](./ONBOARDING.md#-debugging-comandos-útiles)

---

## 📊 Flujo Visual

```
┌─ ESTUDIANTE ──────────────────────────────────────────┐
│                                                        │
│  1. Leer SETUP.md                                     │
│     ↓                                                  │
│  2. Instalar Docker Desktop                           │
│     ↓                                                  │
│  3. Ejecutar: bash scripts/quick-start.sh             │
│     ↓                                                  │
│  4. ✅ Docker automáticamente:                         │
│     • Construye imagen                                │
│     • Ejecuta entrenamientos                          │
│     • Inicia MLflow UI (puerto 5000)                  │
│     • Inicia Model Serving (puerto 9000)             │
│     ↓                                                  │
│  5. Leer ONBOARDING.md (Paso por paso)               │
│     ↓                                                  │
│  6. Explorar:                                         │
│     • http://localhost:5000 (MLflow UI)              │
│     • Hacer predicciones (curl)                       │
│     ↓                                                  │
│  7. Referencia: README.md (cuando necesites)         │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 🎨 Casos de Uso

### Caso 1: "Quiero empezar de cero"
```
SETUP.md → ONBOARDING.md → Experimenta → README.md
```

### Caso 2: "Quiero solo correr y explorar"
```
bash scripts/quick-start.sh → http://localhost:5000
```

### Caso 3: "Quiero entender todo a fondo"
```
SETUP.md → ONBOARDING.md → README.md → Dockerfile → scripts/
```

### Caso 4: "Tengo problema"
```
Buscar en SETUP.md Troubleshooting 
→ O en ONBOARDING.md Debugging 
→ O en README.md Troubleshooting Avanzado
```

---

## ✨ Características

✅ **Completamente Dockerizado**  
Todo corre en un contenedor isolado

✅ **Auto-orquestado**  
MLflow UI + Model Serving en background

✅ **Multi-plataforma**  
Funciona en macOS, Windows (WSL2), Linux

✅ **Apple Silicon Listo**  
Detecta arquitectura automáticamente

✅ **Reproducible**  
Mismo ambiente para todos los estudiantes

✅ **Sin Dependencias Locales**  
Solo necesitas Docker Desktop

---

## 🚀 ¡Listo para Comenzar!

**Elige tu camino:**

1. **Novato con Docker:** [SETUP.md](./SETUP.md)
2. **Quiero ir rápido:** `bash scripts/quick-start.sh`
3. **Quiero aprender todo:** [ONBOARDING.md](./ONBOARDING.md)
4. **Necesito referencia:** [README.md](./README.md)

---

**Última actualización:** 10 de Noviembre, 2024

**Preguntas?** Ver sección "🐛 Troubleshooting" en cada documento

