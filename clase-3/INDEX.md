# Índice Completo - Clase 3: Model Monitoring

## 📊 Resumen del Proyecto

- **Total de líneas de código Python**: 1,080+
- **Dockerfiles**: 3 (MLflow, Monitoring, base Python)
- **Servicios Docker**: 3 (MLflow:5000, Evidently:8000, Monitoring)
- **Notebooks Jupyter**: 2 (básico + avanzado)
- **Reportes HTML**: Dinámicos (generados por runs)
- **Dataset**: 1,000 muestras con 10 features

---

## 🗂️ Estructura de Archivos

```
clase-3/
│
├── COMIENZA_AQUI.txt              ← EMPIEZA AQUÍ (Quick start)
├── README.md                      ← Documentación completa
├── FAQ.md                         ← Preguntas frecuentes
├── INDEX.md                       ← Este archivo
├── SETUP_MACOS.md                 ← Guía específica para macOS
├── docker-compose.yml             ← Orquestación de 3 servicios
│
├── 📁 data/
│   ├── dataset.csv                ← Dataset sintético (1,000 muestras)
│   └── generate_dataset.py        ← Script para regenerar dataset
│
├── 📁 mlflow/
│   ├── Dockerfile                 ← Imagen MLflow personalizada
│   └── mlflow_data/               ← Volumen persistente
│       ├── mlflow.db              ← SQLite backend
│       ├── artifacts/             ← Modelos y reportes
│       └── .gitkeep
│
├── 📁 monitoring/
│   ├── Dockerfile                 ← Imagen de scripts
│   ├── requirements.txt            ← Dependencias (PyML + Evidently)
│   ├── train_and_monitor.py       ← Script principal (280 líneas)
│   ├── simulate_drift.py          ← Simulación de drift (250 líneas)
│   └── utils.py                   ← Funciones auxiliares (opcional)
│
├── 📁 evidently-service/
│   ├── Dockerfile                 ← Imagen Evidently (opcional)
│   ├── config.yaml                ← Configuración de proyectos
│   └── workspace/                 ← Volumen persistente
│       └── .gitkeep
│
├── 📁 notebooks/
│   ├── 01_basic_monitoring.ipynb  ← Tutorial paso a paso (~15 celdas)
│   └── 02_drift_simulation.ipynb  ← Análisis avanzado (~12 celdas)
│
├── 📁 reports/
│   └── run_*.html                 ← Reportes generados dinámicamente
│
└── 📁 scripts/
    └── quick-start.sh             ← Helper script para comandos comunes
```

---

## 🔑 Archivos Clave

### 1. **docker-compose.yml** (2,680 bytes)
Orquesta 3 servicios:
- **MLflow Server** (puerto 5000)
  - Backend: SQLite
  - Artifact root: `/mlflow_data/artifacts`
  - Health check: curl http://localhost:5000

- **Evidently Service** (puerto 8000)
  - Workspace: `/app/workspace`
  - Config: `/app/config.yaml`
  - Health check: curl http://localhost:8000

- **Monitoring** (sin puerto)
  - Modo desarrollo: `tail -f /dev/null`
  - Volúmenes: data, reports
  - Env vars: MLFLOW_TRACKING_URI, EVIDENTLY_SERVICE_URL

### 2. **monitoring/train_and_monitor.py** (280 líneas)
Workflow completo:
1. Carga datos desde `/app/data/dataset.csv`
2. Train/test split estratificado
3. Entrena RandomForestClassifier
4. Logging en MLflow (params, metrics, model)
5. Genera reportes Evidently (3 tipos)
6. Envía datos a Evidently Service
7. Imprime URLs de acceso

**Funciones principales:**
- `load_and_prepare_data()` - Carga y validación
- `split_data()` - Train/test split
- `train_model()` - Entrenamiento + CV
- `evaluate_model()` - Cálculo de métricas
- `setup_mlflow()` - Configuración de tracking
- `log_to_mlflow()` - Logging de experimentos
- `generate_evidently_reports()` - Generación de reportes
- `send_to_evidently_service()` - Envío a API

### 3. **monitoring/simulate_drift.py** (250 líneas)
Simulación de 4 escenarios de drift:
1. **Sin Drift** - Baseline (distribución normal)
2. **Covariate Shift** - Features cambian (+0.5 media)
3. **Label Shift** - Clases desbalanceadas (80/20)
4. **Feature Drift** - Outliers (10%) + ruido (σ=0.3)

**Funciones principales:**
- `load_reference_data()` - Carga datos base
- `generate_baseline_data()` - Escenario 1
- `generate_covariate_shift_data()` - Escenario 2
- `generate_label_shift_data()` - Escenario 3
- `generate_feature_drift_data()` - Escenario 4
- `generate_drift_report()` - Reporte Evidently
- `log_scenario_to_mlflow()` - Logging en MLflow

### 4. **monitoring/requirements.txt** (13 paquetes)
```
mlflow==2.12.1
evidently==0.4.16
scikit-learn==1.3.0
numpy==1.24.3
pandas==2.0.3
requests==2.31.0
python-dotenv==1.0.0
pyyaml==6.0
ipython==8.14.0
jupyter==1.0.0
```

### 5. **evidently-service/config.yaml**
Configuración de monitoreo:
- Proyectos de monitoreo
- Métricas a trackear
- Snapshots de datos
- Umbrales de alertas
- Features a monitorear

### 6. **notebooks/01_basic_monitoring.ipynb** (15 celdas)
Tutorial paso a paso:
1. Setup y verificación de ambiente
2. Importación de librerías
3. Carga y exploración de datos
4. Preparación y train/test split
5. Entrenamiento del modelo
6. Evaluación y feature importance
7. Configuración de MLflow
8. Logging de parámetros, métricas, modelo
9. Generación de reportes Evidently
10. Acceso a interfaces web
11. Ejercicio: tabla comparativa

### 7. **notebooks/02_drift_simulation.ipynb** (12 celdas)
Análisis avanzado:
1. Teoría de tipos de drift
2. Setup y carga de datos
3. Entrenamiento de modelo base
4. Escenario 1: Sin drift (baseline)
5. Escenario 2: Covariate shift
6. Escenario 3: Label shift
7. Escenario 4: Feature drift
8. Comparación de escenarios
9. Análisis de degradación
10. Conclusiones y recomendaciones

---

## 🚀 Flujo de Ejecución

### Paso 1: Inicio de Servicios
```
docker-compose up -d
         ↓
[MLflow Server inicializa SQLite]
[Evidently Service crea workspace]
[Monitoring container listo para comandos]
```

### Paso 2: Entrenamiento Base
```
docker-compose exec monitoring python train_and_monitor.py
         ↓
[Carga dataset.csv]
         ↓
[Split 80/20 estratificado]
         ↓
[Entrena RandomForest + CV]
         ↓
[Calcula metrics: accuracy, precision, recall, f1, roc_auc]
         ↓
[Logging en MLflow: params + metrics + model + CV]
         ↓
[Genera 3 reportes Evidently: classification, drift, quality]
         ↓
[Guarda reportes HTML en /app/reports/]
         ↓
[Imprime URLs y próximos pasos]
```

### Paso 3: Simulación de Drift
```
docker-compose exec monitoring python simulate_drift.py
         ↓
[Carga modelo base entrenado]
         ↓
[Genera 4 datasets con diferentes tipos de drift]
         ↓
[Para cada escenario:
  - Genera reporte Evidently
  - Calcula métricas
  - Registra run en MLflow con tags (drift_type, severity)]
         ↓
[Imprime tabla comparativa de degradación]
```

### Paso 4: Exploración de Resultados
```
Opción A: MLflow UI
http://localhost:5000
  → Experimento: "Model Monitoring - Clase 3"
  → Visualizar runs
  → Comparar parámetros/métricas
  → Descargar artefactos

Opción B: Evidently Dashboard
http://localhost:8000
  → Proyectos de monitoreo
  → Reportes interactivos
  → Gráficos de drift

Opción C: Reportes HTML locales
./reports/run_*.html
  → Abrir en navegador
  → Análisis offline
```

---

## 📚 Conceptos Cubiertos

### Machine Learning
- ✅ Clasificación binaria
- ✅ Random Forest
- ✅ Validación cruzada
- ✅ Métricas: Accuracy, Precision, Recall, F1, ROC-AUC
- ✅ Feature importance
- ✅ Train/test split estratificado

### MLOps
- ✅ Experiment tracking
- ✅ Parameter logging
- ✅ Model versioning
- ✅ Artifact management
- ✅ Reproducibilidad

### Monitoreo
- ✅ Data drift detection
- ✅ Concept drift (teórico)
- ✅ Prediction drift
- ✅ Data quality metrics
- ✅ Drift types (covariate, label, feature)

### Docker
- ✅ Dockerfiles multi-layer
- ✅ Docker Compose orchestration
- ✅ Networking entre containers
- ✅ Volume mounting (persistencia)
- ✅ Health checks
- ✅ Environment variables

### Herramientas
- ✅ MLflow 2.12.1
- ✅ Evidently AI 0.4.16
- ✅ scikit-learn 1.3.0
- ✅ pandas, numpy
- ✅ Docker & Docker Compose

---

## 🎯 Ejercicios Incluidos

### Ejercicio 1: Básico
**Objetivo:** Familiarizarse con el workflow
```
docker-compose up -d
docker-compose exec monitoring python train_and_monitor.py
open http://localhost:5000
```
**Tareas:**
- Ver experimento en MLflow
- Explorar reportes HTML
- Notar tres reportes generados

### Ejercicio 2: Intermedioario
**Objetivo:** Usar MLflow para comparación
```
# Ejecutar 3 veces con diferentes parámetros
docker-compose exec monitoring python train_and_monitor.py
# (Cambiar n_estimators 50 → 100 → 200)
```
**Tareas:**
- Comparar 3 runs en MLflow
- Identificar mejor configuración
- Analizar trade-offs

### Ejercicio 3: Avanzado
**Objetivo:** Simulación de drift
```
docker-compose exec monitoring python simulate_drift.py
```
**Tareas:**
- Ver 4 escenarios de drift
- Comparar degradación por tipo
- Analizar impacto en métricas
- Identificar el más crítico

### Ejercicio 4: Extra
**Objetivo:** Personalización
**Tareas:**
- Cambiar modelo (XGBoost)
- Agregar dataset real
- Crear métrica personalizada
- Integrar con sistema propio

---

## ✅ Checklist de Validación

Antes de considerar Clase 3 completada:

- [ ] `docker-compose up -d` levanta 3 servicios sin errores
- [ ] MLflow UI accesible en http://localhost:5000
- [ ] Evidently Dashboard accesible en http://localhost:8000
- [ ] `python train_and_monitor.py` completa sin errores
- [ ] Se genera experimento "Model Monitoring - Clase 3"
- [ ] Se generan 3 reportes HTML en `/reports/`
- [ ] Al menos 2 runs visibles en MLflow
- [ ] `python simulate_drift.py` genera 4 escenarios
- [ ] Tags de drift visibles en MLflow (drift_type, drift_severity)
- [ ] Datos persisten después de `docker-compose down`
- [ ] Notebooks ejecutables sin errores
- [ ] Se entienden conceptos: drift, covariate shift, label shift

---

## 📈 Progresión de Aprendizaje

**Sesión 1-2 (Fundamentals)**
- Setup inicial
- Conceptos básicos de monitoreo
- Ejecutar entrenamiento
- Explorar MLflow UI

**Sesión 3-4 (Intermediate)**
- Comparar múltiples runs
- Analizar reportes Evidently
- Entender tipos de drift
- Cambiar hiperparámetros

**Sesión 5+ (Advanced)**
- Simulación de drift customizada
- Integración con sistemas
- Escalabilidad (Clase 4)
- Casos de uso reales

---

## 🔄 Preparación para Clase 4

Conceptos reutilizados en Kubernetes:
- ✅ Docker images → Kubernetes Deployments
- ✅ docker-compose.yml → Kubernetes manifests
- ✅ Volúmenes locales → PersistentVolumes
- ✅ Networking local → Services y Ingress
- ✅ Health checks → Probes (liveness, readiness)
- ✅ Environment vars → ConfigMaps y Secrets

---

## 📞 Ayuda Rápida

**Está todo en estos archivos:**

1. **COMIENZA_AQUI.txt** - Quick start (3 pasos)
2. **README.md** - Documentación completa
3. **FAQ.md** - Respuestas a dudas frecuentes
4. **SETUP_MACOS.md** - Guía específica para Mac
5. **notebooks/** - Tutoriales interactivos

**¿Duda?**
→ Revisa FAQ.md
→ Lee la sección relevante de README.md
→ Consulta los logs: `docker-compose logs -f`

---

## 📊 Métricas del Proyecto

| Métrica | Valor |
|---------|-------|
| Líneas de código Python | 1,080+ |
| Líneas de documentación | 2,000+ |
| Servicios Docker | 3 |
| Notebooks Jupyter | 2 |
| Ejercicios prácticos | 4 |
| Tipos de drift simulados | 4 |
| Reportes generados por run | 3 |
| Parámetros configurables | 15+ |
| Métricas rastreadas | 8+ |

---

¡Bienvenido a Clase 3! 🎓

Comienza por `COMIENZA_AQUI.txt` y sigue el flujo paso a paso.

```bash
docker-compose up -d
docker-compose exec monitoring python train_and_monitor.py
open http://localhost:5000
```

¡Éxito! 🚀

