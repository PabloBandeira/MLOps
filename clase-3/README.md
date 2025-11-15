# Clase 3: Model Monitoring y Drift Detection con Evidently + MLflow

> **Maestría en Ciencia de Datos** | MLOps Práctico | Monitoreo de Modelos en Producción

## 📚 Introducción a Model Monitoring

### ¿Por qué Monitorear Modelos?

En producción, los modelos de machine learning no operan en un vacío. Los datos del mundo real cambian constantemente, y cuando las características de esos datos difieren significativamente de los datos con los que fue entrenado el modelo, el performance degrada. Este fenómeno se conoce como **drift**.

**Model Monitoring** es la práctica de supervisar el comportamiento del modelo en producción para:

- **Detectar degradación de performance** antes de afectar usuarios
- **Identificar cambios en datos** (data drift) que requieran re-entrenamiento
- **Alertar automáticamente** sobre anomalías
- **Mantener trazabilidad** de decisiones y cambios
- **Preparar datos** para re-entrenamiento

### El Stack de Monitoreo: Evidently + MLflow

```
┌─────────────────────────────────────────────────────────────┐
│                    CLASE 3: ARQUITECTURA                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌────────────┐│
│  │   MLflow     │      │ Evidently    │      │ Monitoring││
│  │   Server     │◄────►│  Service     │◄────►│  Scripts   ││
│  │ :5000        │      │ :8000        │      │            ││
│  └──────────────┘      └──────────────┘      └────────────┘│
│       ▲                      ▲                      ▲        │
│       │                      │                      │        │
│       └──────────────┬───────┴──────────────┬───────┘        │
│                      │                      │                │
│          [Volumen: mlflow_data]  [Volumen: workspace]       │
│          [SQLite Backend]         [Datos de monitoreo]       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**MLflow**: Tracking y gestión de experimentos
- Backend SQLite para persistencia (sin PostgreSQL)
- Artifact storage para modelos y reportes
- UI web para exploración de runs

**Evidently**: Detección de drift y monitoreo
- Reportes HTML con análisis detallado
- UI web con dashboards en tiempo real
- Métricas de data quality y drift

---

## 🏗️ Arquitectura del Sistema

### Servicios Docker

#### 1. **MLflow Server** (Puerto 5000)

```
MLflow Container
├── Backend: SQLite (/mlflow_data/mlflow.db)
├── Artifacts: /mlflow_data/artifacts
└── UI: http://localhost:5000
```

- Almacena parámetros, métricas y artefactos
- Facilita comparación de experimentos
- Persistencia a través de volumen Docker

#### 2. **Evidently Service** (Puerto 8000)

```
Evidently Container
├── Workspace: /app/workspace
├── Proyectos de monitoreo
├── Reportes JSON
└── UI: http://localhost:8000
```

- API REST para enviar datos
- Detección automática de drift
- Dashboard web interactivo

#### 3. **Monitoring Scripts** (Sin puerto)

```
Monitoring Container
├── train_and_monitor.py - Workflow principal
├── simulate_drift.py - Simulación de drift
├── Data: /app/data/
└── Reports: /app/reports/
```

- Scripts ejecutables manualmente
- Comunicación con MLflow y Evidently
- Generación de reportes HTML

### Networking

Los tres servicios se comunican a través de una red Docker compartida:

```
monitoring → mlflow:5000  (Tracking de experimentos)
monitoring → evidently:8000 (Envío de datos para monitoreo)
```

### ¿Por qué SQLite?

- **Simplicidad**: No requiere servidor PostgreSQL separado
- **Desarrollo local**: Ideal para ambiente educativo
- **Portabilidad**: Un archivo `.db` contiene todo
- **Perfecto para Clase 3**: En Clase 4 escalaremos a Kubernetes con PostgrSQL

---

## 📋 Requisitos Previos

- **Docker Desktop** instalado (Mac, Windows o Linux)
- **Mínimo 4GB RAM** disponible
- **Puertos 5000 y 8000** sin uso
- **Git** para versión de código

Verifica instalación:

```bash
docker --version
docker-compose --version
```

---

## 🚀 Setup e Inicio Rápido

### 1. Navegar al Directorio

```bash
cd /Users/pablo/Desktop/MLops/clase-3
```

### 2. Levantar Servicios

```bash
# Construir y lanzar los 3 servicios
docker-compose up -d

# Verificar que están corriendo
docker-compose ps

# Ver logs de servicios
docker-compose logs -f
```

**Salida esperada:**

```
STATUS
mlflow-server         running
evidently-service     running
monitoring-app        running
```

### 3. Acceder a Interfaces Web

- **MLflow UI**: http://localhost:5000
- **Evidently Dashboard**: http://localhost:8000

### 4. Ejecutar Entrenamiento Base

```bash
# Entrenar modelo e iniciar monitoreo
docker-compose exec monitoring python train_and_monitor.py
```

**¿Qué sucede?**

1. ✓ Carga dataset
2. ✓ Split train/test
3. ✓ Entrena RandomForest
4. ✓ Calcula métricas
5. ✓ Registra en MLflow
6. ✓ Genera reportes Evidently
7. ✓ Envía datos a Evidently Service

### 5. Simular Drift

```bash
# Ejecutar simulación con 4 escenarios de drift
docker-compose exec monitoring python simulate_drift.py
```

**Escenarios generados:**

1. **Sin Drift**: Datos con distribución normal
2. **Covariate Shift**: Features cambian, targets igual
3. **Label Shift**: Proporción de clases cambia
4. **Feature Drift**: Outliers, ruido, cambios de escala

### 6. Explorar Resultados

**En MLflow UI:**
- Experimento: "Model Monitoring - Clase 3"
- Compara runs con diferentes configuraciones
- Visualiza métricas y tags de drift

**En Evidently Dashboard:**
- Proyectos de monitoreo creados
- Reportes HTML disponibles
- Gráficos de drift detection

---

## 🏋️ Ejercicios Prácticos

### Ejercicio 1: Entrenar Modelo Base y Explorar Reportes

**Objetivo**: Familiarizarse con el workflow básico

```bash
# 1. Levantar servicios
docker-compose up -d

# 2. Ejecutar entrenamiento
docker-compose exec monitoring python train_and_monitor.py

# 3. Abrir MLflow UI
# http://localhost:5000
# → Buscar experimento "Model Monitoring - Clase 3"
# → Ver métricas: accuracy, precision, recall, f1, roc_auc

# 4. Abrir Evidently Dashboard
# http://localhost:8000
# → Ver proyecto creado
# → Explorar reportes de drift y quality

# 5. Abrir reportes HTML locales
# → Abre archivo: ./reports/run_*_classification_report.html
```

### Ejercicio 2: Entrenar Múltiples Modelos y Compararlos

**Objetivo**: Usar MLflow para comparación de experimentos

```bash
# Abrir archivo: monitoring/train_and_monitor.py
# Cambiar hiperparámetros:
# - n_estimators: 50, 100, 200
# - max_depth: 5, 10, 15

# Ejecutar 3 veces con diferentes valores
docker-compose exec monitoring python train_and_monitor.py
docker-compose exec monitoring python train_and_monitor.py
docker-compose exec monitoring python train_and_monitor.py

# En MLflow UI:
# Comparar métricas entre los 3 runs
# ¿Cuál tuvo mejor performance?
# ¿Cuáles fueron los trade-offs?
```

### Ejercicio 3: Simulación de Drift y Detección

**Objetivo**: Entender tipos de drift y su impacto

```bash
# 1. Ejecutar simulación
docker-compose exec monitoring python simulate_drift.py

# 2. En MLflow UI:
# → Filtrar por tag: run_type = "drift_simulation"
# → Ver tags: drift_type, drift_severity
# → Comparar métricas entre escenarios

# 3. Abrir reportes HTML:
# → drift_none_*.html (baseline)
# → drift_covariate_*.html (features cambian)
# → drift_label_*.html (clases desbalanceadas)
# → drift_feature_*.html (outliers y ruido)

# 4. Análisis:
# ¿En cuál escenario el modelo tuvo peor performance?
# ¿Qué tipo de drift es más peligroso?
```

### Ejercicio 4: Análisis Avanzado de Dashboards

**Objetivo**: Interpretación profunda de métricas

```bash
# 1. En Evidently Dashboard (http://localhost:8000):
# → Explorar proyectos de monitoreo
# → Ver evolución de métricas en el tiempo
# → Identificar puntos de degradación

# 2. En MLflow UI (http://localhost:5000):
# → Crear custom charts
# → Comparar 3+ runs simultáneamente
# → Exportar métricas a CSV (si aplica)

# 3. Preguntas de análisis:
# - ¿Cuándo se recomienda re-entrenar?
# - ¿Qué features son más propensos a drift?
# - ¿Cuál es el umbral seguro de degradación?
```

---

## 📖 Conceptos Clave Explicados

### Data Drift vs Concept Drift

**Data Drift (Covariate Shift)**
- Cambio en distribución de features (X)
- Modelo puede adaptarse re-entrenando
- Ejemplo: Usuarios nuevos con diferente perfil

**Concept Drift**
- Cambio en la relación features → target (P(Y|X))
- Requiere re-entrenamiento urgente
- Ejemplo: Cambio en las reglas de negocio

**Prediction Drift**
- Cambio en distribución de predicciones
- Síntoma de data o concept drift
- Red flag para revisión manual

### Métricas Evidently

| Métrica | Qué mide | Umbral típico |
|---------|----------|--------------|
| **PSI** (Population Stability Index) | Cambio distribución | > 0.2 = alerta |
| **KL Divergence** | Divergencia Kullback-Leibler | > 0.1 = alerta |
| **JS Distance** | Jensen-Shannon distance | > 0.1 = alerta |
| **Wasserstein** | Distancia óptima entre distribuciones | > 0.15 = alerta |

### Cuándo Re-entrenar

```
Performance Actual < Performance Baseline - Threshold
                    ↓
            Re-entrenar Recomendado
                    ↓
        Validar Nuevo Modelo
                    ↓
        Deploy en Producción
```

**Umbrales sugeridos por métrica:**
- Accuracy: -0.05 (caída del 5%)
- Precision: -0.10
- Recall: -0.10
- F1-score: -0.08

---

## 🔧 Troubleshooting Común

### Problema: Servicios no inician

**Síntoma:**
```
ERROR: Service 'mlflow' failed to start
```

**Solución:**
```bash
# Ver logs detallados
docker-compose logs mlflow

# Verificar puertos disponibles
lsof -i :5000
lsof -i :8000

# Cambiar puertos en docker-compose.yml si están ocupados
# mlflow: "5001:5000"
# evidently: "8001:8000"
```

### Problema: Error de conexión a MLflow

**Síntoma:**
```
ConnectionRefusedError: [Errno 111] Connection refused
```

**Solución:**
```bash
# 1. Verificar que MLflow está corriendo
docker-compose ps

# 2. Esperar a que MLflow inicialice (20-30s)
docker-compose logs mlflow | grep "Listening"

# 3. Verificar networking
docker-compose exec monitoring ping mlflow
```

### Problema: Volúmenes sin permisos (Linux)

**Síntoma:**
```
Permission denied writing to /mlflow_data/
```

**Solución:**
```bash
# Cambiar permisos del directorio
sudo chown -R 1000:1000 ./mlflow/mlflow_data
sudo chown -R 1000:1000 ./evidently-service/workspace
```

### Problema: Dataset no encontrado

**Síntoma:**
```
FileNotFoundError: /app/data/dataset.csv
```

**Solución:**
```bash
# Dataset debe estar presente
ls -la ./data/dataset.csv

# Si no existe, regenerar
python3 ./data/generate_dataset.py
```

### Limpiar y Reiniciar

```bash
# Detener y eliminar contenedores
docker-compose down

# Eliminar volúmenes (⚠️ borra datos)
docker-compose down -v

# Limpiar imágenes
docker-compose down --rmi all

# Reiniciar fresco
docker-compose up -d
```

---

## 📁 Estructura de Archivos

```
clase-3/
├── README.md                              # Esta guía
├── docker-compose.yml                     # Orquestación de 3 servicios
├── .env.example                           # Variables de entorno template
│
├── data/
│   ├── dataset.csv                        # Dataset de entrenamiento (1000 muestras)
│   └── generate_dataset.py                # Script para generar dataset
│
├── mlflow/
│   ├── Dockerfile                         # Imagen MLflow personalizada
│   └── mlflow_data/                       # Volumen persistente
│       ├── mlflow.db                      # SQLite backend
│       └── artifacts/                     # Modelos y reportes
│
├── monitoring/
│   ├── Dockerfile                         # Imagen para scripts
│   ├── requirements.txt                   # Dependencias Python
│   ├── train_and_monitor.py               # Workflow principal (~280 líneas)
│   ├── simulate_drift.py                  # Simulación de drift (~250 líneas)
│   └── utils.py                           # Funciones auxiliares (opcional)
│
├── evidently-service/
│   ├── Dockerfile                         # Dockerfile para Evidently (si aplica)
│   ├── config.yaml                        # Configuración de monitoreo
│   └── workspace/                         # Volumen persistente
│       └── projects/                      # Proyectos de monitoreo
│
├── notebooks/
│   ├── 01_basic_monitoring.ipynb          # Tutorial interactivo básico
│   └── 02_drift_simulation.ipynb          # Análisis avanzado de drift
│
└── reports/                               # Reportes HTML backup
    └── run_*.html                         # Reportes generados por runs
```

---

## 🎓 Próximos Pasos (Clase 4: Kubernetes)

Esta clase prepara el terreno para:

**Clase 4: Escalabilidad y Orquestación con Kubernetes**

- Migrar docker-compose → Kubernetes manifests
- Multi-replica deployments
- Ingress controllers para MLflow + Evidently
- StatefulSets para persistencia
- Scaling horizontal de monitoring workers
- CI/CD automático con GitOps

**Conceptos que reutilizaremos:**
- Networking (ahora con services K8s)
- Volúmenes (ahora con PVCs)
- Health checks (ahora con probes)
- Variables de entorno (ahora con ConfigMaps)

---

## 📚 Referencias Técnicas

### Documentación Oficial

- [MLflow Tracking Documentation](https://mlflow.org/docs/latest/tracking.html)
- [Evidently AI Docs](https://docs.evidentlyai.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/compose-file-v3/)

### Artículos sobre Drift

- "Machine Learning Monitoring: Bridging the Gap Between ML Development and Operation" - Datadog
- "On Learning Invariant Representations" - DeepMind Blog
- "A Comparative Analysis of Concept Drift Detection Strategies" - IEEE

### Conjuntos de Datos

- Iris (usado en clases 1-2)
- Synthetic dataset generado (Clase 3)
- Real-world drifted datasets (para investigación)

---

## 👥 Ayuda y Soporte

### Comandos Útiles

```bash
# Ver estado de servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f monitoring

# Ejecutar comando en contenedor
docker-compose exec monitoring bash

# Entrar a shell interactivo
docker-compose exec monitoring python

# Limpiar volumes
docker volume prune

# Inspeccionar volumen
docker volume inspect clase-3_mlflow-data

# Copiar archivo del contenedor
docker-compose cp monitoring:/app/reports/report.html ./local/
```

### Preguntas Frecuentes

**P: ¿Cuánto tiempo tarda el primer entrenamiento?**
R: 30-60 segundos incluyendo setup de MLflow

**P: ¿Puedo cambiar el modelo (Random Forest → XGBoost)?**
R: Sí, modificar `train_and_monitor.py` línea ~130

**P: ¿Cómo exporto datos de MLflow?**
R: MLflow proporciona API REST en `/api/` o exportar desde UI

**P: ¿Qué pasa con los datos si elimino volúmenes?**
R: Se pierden. Hacer backup con: `docker-compose cp`

---

## 📝 Licencia y Créditos

Clase 3 - MLOps Maestría en Ciencia de Datos

**Stack Utilizado:**
- Python 3.11
- MLflow 2.12.1
- Evidently 0.4.16
- scikit-learn 1.3.0
- Docker & Docker Compose

---

## ✅ Checklist de Verificación

Antes de finalizar la clase, verifica:

- [ ] docker-compose up levanta 3 servicios sin errores
- [ ] MLflow UI accesible en http://localhost:5000
- [ ] Evidently Dashboard accesible en http://localhost:8000
- [ ] `train_and_monitor.py` completa sin errores
- [ ] Reportes HTML generados en `/reports/`
- [ ] Al menos 2 runs visibles en MLflow UI
- [ ] `simulate_drift.py` genera 4 escenarios
- [ ] Tags de drift visible en MLflow (drift_type, drift_severity)
- [ ] Datos persisten después de `docker-compose down`
- [ ] Notebooks ejecutables sin errores

---

**¡Listo para comenzar!** 🎯

```bash
cd clase-3
docker-compose up -d
docker-compose exec monitoring python train_and_monitor.py
# Abre http://localhost:5000 en tu navegador
```

