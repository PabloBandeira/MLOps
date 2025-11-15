# Preguntas Frecuentes - Clase 3

## Instalación y Setup

### P: ¿Qué necesito para ejecutar esto?

**R:** Solo necesitas:
- Docker Desktop instalado
- ~4GB RAM disponible
- Terminal/Shell
- Navegador web

### P: ¿Funciona en Windows?

**R:** Sí, Docker Compose funciona en Windows 10/11.
- Instala Docker Desktop para Windows
- Usa PowerShell o WSL2
- Los puertos (5000, 8000) deben estar disponibles

### P: ¿Cuánto tiempo tarda el primer inicio?

**R:** Aproximadamente:
- Primera construcción de imágenes: 5-10 minutos
- Inicialización de servicios: 30-60 segundos
- Primer entrenamiento: 30-120 segundos

### P: ¿Cuántos recursos consume?

**R:** Aproximadamente:
- CPU: 2-3 cores durante entrenamiento, <1 core idle
- RAM: 500MB-1GB base, +500MB durante training
- Disco: ~500MB para imágenes + datos persistentes

---

## Operación

### P: ¿Cómo cambio de modelo (ej: XGBoost)?

**R:** Edita `monitoring/train_and_monitor.py`:

```python
# Línea ~130 - Cambiar de RandomForest a XGBoost
from xgboost import XGBClassifier

model = XGBClassifier(
    n_estimators=100,
    max_depth=10,
    random_state=42
)
```

También actualiza `requirements.txt` con `xgboost==1.7.6`

### P: ¿Cómo agrego más features al dataset?

**R:** Dos opciones:

**Opción 1:** Generar con `generate_dataset.py`
```python
# Cambiar n_features en la línea ~30
X, y = make_classification(
    n_samples=1000,
    n_features=20,  # Cambiar aquí
    ...
)
```

**Opción 2:** Reemplazar `data/dataset.csv` con tu CSV

### P: ¿Puedo usar un dataset real?

**R:** Sí, reemplaza `data/dataset.csv` con tu CSV:
- Columnas numéricas
- Una columna llamada `target` (0/1 para clasificación)
- Sin valores faltantes (o manéjalos con preprocessing)

### P: ¿Cómo cambio los hiperparámetros?

**R:** Edita `monitoring/train_and_monitor.py` línea ~160:

```python
hyperparams = {
    'n_estimators': 50,      # Cambiar aquí
    'max_depth': 5,          # o aquí
    'min_samples_split': 10, # o aquí
    'random_state': 42,
    'n_jobs': -1
}
```

---

## Monitoreo y Reportes

### P: ¿Qué es Data Drift?

**R:** Cambio en la distribución de datos en producción vs training.

Tipos:
- **Covariate Shift**: Features cambian
- **Label Shift**: Proporción de clases cambia
- **Feature Drift**: Ruido, outliers, valores faltantes

### P: ¿Cuándo re-entrenar?

**R:** Cuando:
- Degradación > 5% en accuracy
- Data drift score > 0.5 (PSI)
- Más de X% de datos nuevos
- Cambio significativo en business logic

### P: ¿Dónde está mi reporte?

**R:** Los reportes se guardan en:
- HTML: `/reports/run_*.html`
- MLflow: http://localhost:5000 → Artifacts
- Evidently Service: http://localhost:8000 → Projects

### P: ¿Cómo comparo múltiples runs?

**R:** En MLflow UI:
1. Ve a Experiment "Model Monitoring - Clase 3"
2. Selecciona 2+ runs (checkbox)
3. Haz clic en "Compare"
4. Visualiza lado a lado

---

## Troubleshooting

### P: "ConnectionRefusedError: MLflow"

**R:** MLflow aún no está listo. Espera:
```bash
docker-compose logs mlflow | grep "Listening"
```

Espera a que veas el mensaje "Listening on http://0.0.0.0:5000"

### P: "Port already in use"

**R:** Otro proceso usa el puerto:
```bash
# Encontrar qué
lsof -i :5000
lsof -i :8000

# O cambiar puerto en docker-compose.yml
```

### P: "Cannot pull image"

**R:** Problema de red/internet. Intenta:
```bash
docker-compose pull
docker-compose build --no-cache
```

### P: "Out of memory"

**R:** Docker necesita más RAM:
- Docker Desktop → Preferences → Resources
- Aumentar Memory (ej: 4GB → 6GB)
- Reiniciar Docker

### P: "Permission denied" en volúmenes (Linux)

**R:** Cambiar permisos:
```bash
sudo chown -R 1000:1000 mlflow/mlflow_data/
sudo chown -R 1000:1000 evidently-service/workspace/
```

---

## Datos y Persistencia

### P: ¿Dónde se guardan los datos?

**R:** En volúmenes Docker:
- MLflow: `mlflow/mlflow_data/`
- Evidently: `evidently-service/workspace/`
- Reportes HTML: `reports/`

### P: ¿Se pierden los datos al hacer `down`?

**R:** **NO**, con `docker-compose down`:
- Los datos persisten en volúmenes
- Los contenedores se detienen pero no se eliminan

**SÍ se pierden** con `docker-compose down -v`:
- El `-v` elimina volúmenes

### P: ¿Cómo hago backup?

**R:** Copia los directorios:
```bash
cp -r mlflow/mlflow_data ~/Backup/
cp -r evidently-service/workspace ~/Backup/
```

### P: ¿Cómo restauro backup?

**R:** Reemplaza los directorios:
```bash
# Primero detener servicios
docker-compose down

# Copiar backup
cp -r ~/Backup/mlflow_data mlflow/
cp -r ~/Backup/workspace evidently-service/

# Reiniciar
docker-compose up -d
```

---

## MLflow

### P: ¿Qué es un "Run"?

**R:** Un run es una ejecución/experimento registrado.
Incluye:
- Parámetros (hiperparámetros)
- Métricas (accuracy, f1, etc.)
- Artifacts (modelos, gráficos)
- Tags (metadata)

### P: ¿Cómo exporto datos de MLflow?

**R:** Opciones:
1. **UI**: Cada run tiene botón de descarga
2. **API REST**: http://localhost:5000/api
3. **Python SDK**: `mlflow.search_runs()`

### P: ¿Puedo tener múltiples experimentos?

**R:** Sí, el código crea "Model Monitoring - Clase 3".
Puedes crear otros editando `train_and_monitor.py`:

```python
experiment_name = "Mi Nuevo Experimento"
```

---

## Evidently

### P: ¿Qué es PSI (Population Stability Index)?

**R:** Métrica que mide cambio en distribución:
- PSI = 0: Sin cambio
- PSI 0.1-0.25: Cambio leve
- PSI > 0.25: Cambio significativo

### P: ¿Cómo interpreto los reportes?

**R:** Evidently genera:
1. **Classification Metrics**: Performance del modelo
2. **Data Drift**: Cambios en features
3. **Data Quality**: Valores faltantes, outliers

Ve a `http://localhost:8000` para ver dashboards interactivos.

### P: ¿Qué diferencia hay entre una medida estadística?

**R:** Diferentes métricas de drift:
- **PSI**: Kullback-Leibler divergence
- **KL Divergence**: Teórico information theory
- **JS Distance**: Symmetric, bounded [0,1]
- **Wasserstein**: Earth mover's distance

Use la que mejor se ajuste a tus datos.

---

## Desarrollo

### P: ¿Cómo agrego una métrica personalizada?

**R:** Edita `monitoring/train_and_monitor.py` en el log:

```python
# Agregar métrica personalizada
from sklearn.metrics import specificity_score

specificity = specificity_score(y_test, y_pred)
mlflow.log_metric('specificity', specificity)
```

### P: ¿Cómo modifico el reporte Evidently?

**R:** Edita líneas ~180-210 en `train_and_monitor.py`:

```python
from evidently.report import Report
from evidently.metric_preset import (
    ClassificationPreset,
    DataDriftPreset,
    DataQualityPreset
)

# Agregar más presets si los necesitas
```

### P: ¿Cómo integro con mi sistema?

**R:** El flujo es:
```
Scripts Docker → MLflow API → Sistema
             ↓
          Evidently API ↓ Sistema
```

Usa los endpoints REST:
- MLflow: `http://localhost:5000/api`
- Evidently: `http://localhost:8000/api`

---

## Clase 4 (Kubernetes)

### P: ¿Cómo escalo esto a Kubernetes?

**R:** Los Dockerfiles ya son K8s-ready:
1. Cambiar SQLite → PostgreSQL
2. Crear Kubernetes manifests (Deployments, Services)
3. Usar Helm charts si aplica
4. Implementar CI/CD (GitOps)

### P: ¿Qué cambios necesito?

**R:** Principales:
- Docker Compose → Kubernetes YAML
- SQLite → PostgreSQL Service
- Networking local → Ingress controllers
- Volúmenes local → PersistentVolumes

---

## Performance

### P: ¿Cómo hago el entrenamiento más rápido?

**R:** Opciones:
1. Reducir `n_estimators` (100 → 50)
2. Aumentar `random_state` consistency
3. Reducir `max_depth`
4. Usar `n_jobs=-1` (ya configurado)

### P: ¿Cómo optimizo Evidently?

**R:** Evidently es rápido de por sí, pero:
- Usa `DataDriftPreset()` en lugar de todas las métricas
- Reduce el tamaño del dataset para testing rápido
- Ejecuta reportes en paralelo si es posible

---

## Preguntas Conceptuales

### P: ¿Por qué SQLite y no PostgreSQL?

**R:** Para Clase 3:
- SQLite: Simple, no requiere servidor, portable
- PostgreSQL: Overkill para desarrollo educativo

En Clase 4 (Kubernetes) usamos PostgreSQL.

### P: ¿Por qué Evidently y no Prometheus?

**R:** Diferentes herramientas para diferentes casos:
- **Evidently**: Especializado en data drift ML
- **Prometheus**: Métricas de infraestructura general

Ambos complementarios en producción.

### P: ¿Cuándo usar esto en producción?

**R:** Casos ideales:
- Modelos críticos (predicción de precio, diagnóstico)
- Datos que cambian frecuentemente
- Necesidad de auditoría y trazabilidad
- Equipos que necesitan monitoring compartido

---

## Recursos

### Documentación
- [MLflow Official Docs](https://mlflow.org/docs)
- [Evidently AI Docs](https://docs.evidentlyai.com)
- [Docker Compose Reference](https://docs.docker.com/compose)

### Artículos
- "Monitoring Machine Learning Models in Production" - Google Cloud
- "Concept Drift in Learning Systems" - IEEE
- "A Survey on Data Stream Mining" - ACM Computing Surveys

### Comunidades
- MLflow GitHub Discussions
- Evidently AI Slack
- r/MachineLearning

---

## Contacto y Apoyo

Si tienes dudas:
1. Revisa este FAQ
2. Lee el README.md completo
3. Consulta los logs: `docker-compose logs -f`
4. Abre issue en GitHub (si aplica)

¡Éxito con Clase 3! 🚀

