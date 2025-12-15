# 🎯 Ejercicios Prácticos - Clase 4: MLOps en Kubernetes

## 📚 Introducción

Estos ejercicios te permitirán profundizar en los conceptos de MLOps y Kubernetes vistos en clase. Están organizados por nivel de dificultad: **Básico**, **Intermedio** y **Avanzado**.

**Prerequisitos:**
- Haber completado el setup: `./scripts/setup.sh`
- Tener el clúster corriendo
- Haber ejecutado el notebook `01_simulacion.ipynb`

---

## 🟢 Nivel Básico

### **Ejercicio 1: Explorar el Clúster**

**Objetivo:** Familiarizarse con comandos básicos de kubectl.

**Tareas:**

1. Lista todos los pods y anota en qué estado están:
```bash
kubectl get pods
```

2. Obtén información detallada del pod de MLflow:
```bash
kubectl describe pod <nombre-del-pod-mlflow>
```

3. Ver los logs en tiempo real del Iris API:
```bash
kubectl logs -f -l app=iris-api
```

4. Ejecutar un comando dentro del workspace:
```bash
kubectl exec -it <workspace-pod> -- python --version
```

**Preguntas:**
- ¿Cuánta memoria está usando cada pod?
- ¿Cuál es la IP interna de cada pod?
- ¿Qué eventos se registraron durante el startup?

---

### **Ejercicio 2: Modificar Réplicas**

**Objetivo:** Entender el escalado horizontal de pods.

**Tareas:**

1. Verifica las réplicas actuales del Iris API:
```bash
kubectl get deployment iris-api
```

2. Escala a 1 réplica:
```bash
kubectl scale deployment iris-api --replicas=1
```

3. Observa cómo Kubernetes elimina un pod:
```bash
kubectl get pods -w
```

4. Escala a 5 réplicas:
```bash
kubectl scale deployment iris-api --replicas=5
```

5. Desde el notebook, ejecuta predicciones y observa en los logs cómo se distribuyen:
```bash
kubectl logs -f -l app=iris-api --prefix=true
```

**Preguntas:**
- ¿Cuánto tarda en crear un nuevo pod?
- ¿Cómo distribuye Kubernetes las peticiones entre réplicas?
- ¿Qué pasa si todas las réplicas están ocupadas?

---

### **Ejercicio 3: Modificar el Notebook**

**Objetivo:** Personalizar el flujo de simulación.

**Tareas:**

1. En JupyterLab, crea una copia del notebook:
   - File → Make a Copy

2. Modifica el notebook para enviar **200 muestras** en lugar de 50

3. Agrega una nueva métrica a registrar en MLflow:
```python
# Agregar después de las métricas existentes
mlflow.log_metric("min_confidence", df_production['confidence'].min())
mlflow.log_metric("max_confidence", df_production['confidence'].max())
mlflow.log_metric("std_confidence", df_production['confidence'].std())
```

4. Ejecuta el notebook modificado

5. Verifica en MLflow UI que se registraron las nuevas métricas

**Bonus:** Agrega un gráfico de distribución de confianza usando matplotlib.

---

### **Ejercicio 4: Probar el API Directamente**

**Objetivo:** Interactuar con el API de inferencia usando curl o Postman.

**Tareas:**

1. Hacer una predicción desde la terminal:
```bash
curl -X POST http://localhost:30004/predict \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }' | jq
```

2. Obtener información del modelo:
```bash
curl http://localhost:30004/info | jq
```

3. Verificar el health check:
```bash
curl http://localhost:30004/health | jq
```

4. Hacer 10 predicciones en un loop y medir el tiempo:
```bash
time for i in {1..10}; do
  curl -s -X POST http://localhost:30004/predict \
    -H "Content-Type: application/json" \
    -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}' > /dev/null
done
```

**Preguntas:**
- ¿Cuál es el tiempo de respuesta promedio?
- ¿Varía significativamente entre peticiones?
- ¿Qué campos devuelve la respuesta?

---

## 🟡 Nivel Intermedio

### **Ejercicio 5: Simular Alta Carga**

**Objetivo:** Entender el comportamiento bajo carga y load balancing.

**Tareas:**

1. Escala el Iris API a 3 réplicas:
```bash
kubectl scale deployment iris-api --replicas=3
```

2. Crea una nueva celda en el notebook con este código:
```python
import concurrent.futures
import time
from datetime import datetime

def send_prediction(sample_id):
    """Envía una predicción y retorna el tiempo de respuesta"""
    start = time.time()
    try:
        payload = {
            "sepal_length": 5.1 + (sample_id % 3) * 0.1,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2
        }
        response = requests.post(f"{IRIS_API_URL}/predict", json=payload, timeout=10)
        elapsed = time.time() - start
        return {
            'id': sample_id,
            'status': response.status_code,
            'time': elapsed,
            'prediction_id': response.json().get('prediction_id', 'N/A')
        }
    except Exception as e:
        return {'id': sample_id, 'status': 'error', 'time': time.time() - start, 'error': str(e)}

# Prueba de carga: 100 peticiones concurrentes
print("🚀 Iniciando prueba de carga...\n")
start_time = time.time()

with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
    futures = [executor.submit(send_prediction, i) for i in range(100)]
    results = [f.result() for f in concurrent.futures.as_completed(futures)]

total_time = time.time() - start_time

# Análisis de resultados
df_results = pd.DataFrame(results)
successful = df_results[df_results['status'] == 200]

print(f"📊 Resultados de la Prueba de Carga:")
print(f"   Total de peticiones: {len(results)}")
print(f"   Exitosas: {len(successful)}")
print(f"   Fallidas: {len(df_results[df_results['status'] != 200])}")
print(f"   Tiempo total: {total_time:.2f}s")
print(f"   Throughput: {len(results)/total_time:.1f} req/s")
print(f"\n   Tiempo de respuesta:")
print(f"   - Promedio: {successful['time'].mean():.3f}s")
print(f"   - Mínimo: {successful['time'].min():.3f}s")
print(f"   - Máximo: {successful['time'].max():.3f}s")
print(f"   - P95: {successful['time'].quantile(0.95):.3f}s")

# Visualizar distribución de tiempos
import matplotlib.pyplot as plt
plt.figure(figsize=(10, 5))
plt.hist(successful['time'], bins=30, edgecolor='black')
plt.xlabel('Tiempo de Respuesta (s)')
plt.ylabel('Frecuencia')
plt.title('Distribución de Tiempos de Respuesta')
plt.axvline(successful['time'].mean(), color='r', linestyle='--', label=f'Media: {successful["time"].mean():.3f}s')
plt.legend()
plt.show()
```

3. Mientras corre, en otra terminal observa los logs:
```bash
kubectl logs -f -l app=iris-api --prefix=true --max-log-requests=10
```

4. Repite el experimento con 1, 3 y 5 réplicas. Compara los resultados.

**Preguntas:**
- ¿Cómo afecta el número de réplicas al throughput?
- ¿Cuál es el cuello de botella: CPU, memoria, o red?
- ¿A partir de cuántas peticiones concurrentes empiezan a fallar?

---

### **Ejercicio 6: Modificar el Modelo**

**Objetivo:** Implementar cambios en el modelo y redesplegar.

**Tareas:**

1. Modifica `app_iris/train.py` para usar un algoritmo diferente:
```python
# Cambiar de RandomForest a LogisticRegression
from sklearn.linear_model import LogisticRegression

# Entrenar modelo
model = LogisticRegression(max_iter=200, random_state=42)
model.fit(X_train, y_train)
```

2. Actualiza la versión del modelo en `train.py`:
```python
model_artifact = {
    "model": model,
    "feature_names": feature_names,
    "target_names": target_names,
    "accuracy": accuracy,
    "version": "2.0.0"  # ← Cambiar aquí
}
```

3. Reconstruye la imagen:
```bash
cd app_iris
docker build -t iris-api:v2 .
```

4. Carga la nueva imagen al clúster:
```bash
kind load docker-image iris-api:v2 --name mlops-cluster
```

5. Actualiza el deployment para usar la nueva versión:
```bash
kubectl set image deployment/iris-api iris-api=iris-api:v2
```

6. Observa el rolling update:
```bash
kubectl rollout status deployment/iris-api
```

7. Verifica que la nueva versión esté corriendo:
```bash
curl http://localhost:30004/info | jq '.version'
```

8. Ejecuta el notebook de nuevo y compara las métricas en MLflow

**Preguntas:**
- ¿Cambió el accuracy con el nuevo modelo?
- ¿Hubo downtime durante el update?
- ¿Cuánto tardó el rolling update?

**Bonus:** Haz rollback a la versión anterior:
```bash
kubectl rollout undo deployment/iris-api
```

---

### **Ejercicio 7: Configurar Variables de Entorno**

**Objetivo:** Modificar configuración sin reconstruir imágenes.

**Tareas:**

1. Agrega una nueva variable de entorno al workspace editando `infra/workspace.tf`:
```hcl
env {
  name  = "MODEL_THRESHOLD"
  value = "0.7"
}
```

2. Aplica el cambio:
```bash
cd infra
terraform apply
```

3. En el notebook, usa la variable:
```python
import os
threshold = float(os.getenv("MODEL_THRESHOLD", "0.5"))
print(f"Using threshold: {threshold}")

# Filtrar predicciones con baja confianza
high_confidence = df_production[df_production['confidence'] >= threshold]
print(f"Predictions above threshold: {len(high_confidence)}/{len(df_production)}")
```

4. Experimenta con diferentes valores de threshold

**Bonus:** Agrega más variables de entorno:
- `MAX_SAMPLES` - Límite de muestras a procesar
- `DRIFT_THRESHOLD` - Umbral para alertas de drift
- `LOG_LEVEL` - Nivel de logging

---

### **Ejercicio 8: Implementar Health Checks Personalizados**

**Objetivo:** Mejorar la robustez con health checks avanzados.

**Tareas:**

1. Modifica `app_iris/main.py` para agregar un health check más completo:
```python
import time

# Variable global para tracking
last_prediction_time = time.time()
prediction_count = 0

@app.get("/health/detailed")
async def detailed_health():
    """Health check detallado con métricas"""
    uptime = time.time() - startup_time
    time_since_last_prediction = time.time() - last_prediction_time
    
    return {
        "status": "healthy",
        "model_loaded": MODEL is not None,
        "model_version": MODEL_METADATA.get("version", "unknown"),
        "uptime_seconds": round(uptime, 2),
        "predictions_served": prediction_count,
        "time_since_last_prediction": round(time_since_last_prediction, 2),
        "model_accuracy": MODEL_METADATA.get("accuracy", None)
    }

# En la función predict, agregar:
@app.post("/predict", response_model=PredictionResponse)
async def predict(features: IrisFeatures):
    global last_prediction_time, prediction_count
    # ... código existente ...
    
    # Actualizar métricas
    last_prediction_time = time.time()
    prediction_count += 1
    
    # ... resto del código ...
```

2. Reconstruye y redespliega

3. Prueba el nuevo endpoint:
```bash
curl http://localhost:30004/health/detailed | jq
```

4. Modifica el liveness probe en `infra/iris_api.tf` para usar el nuevo endpoint

**Preguntas:**
- ¿Qué métricas adicionales serían útiles?
- ¿Cuándo debería fallar el health check?
- ¿Cómo podrías usar esto para autoscaling?

---

## 🔴 Nivel Avanzado

### **Ejercicio 9: Implementar Horizontal Pod Autoscaler (HPA)**

**Objetivo:** Autoscaling basado en métricas de CPU.

**Prerequisito:** Instalar metrics-server en Kind:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Editar deployment para agregar --kubelet-insecure-tls
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

**Tareas:**

1. Crea un HPA para el Iris API:
```bash
kubectl autoscale deployment iris-api \
  --cpu-percent=50 \
  --min=2 \
  --max=10
```

2. Verifica el HPA:
```bash
kubectl get hpa
kubectl describe hpa iris-api
```

3. Genera carga para trigger el autoscaling:
```python
# En el notebook, ejecutar esto para generar carga sostenida
import concurrent.futures
import time

def continuous_load(duration_seconds=300):
    """Genera carga durante N segundos"""
    start_time = time.time()
    requests_sent = 0
    
    def send_request():
        try:
            response = requests.post(f"{IRIS_API_URL}/predict", 
                json={"sepal_length": 5.1, "sepal_width": 3.5, 
                      "petal_length": 1.4, "petal_width": 0.2}, 
                timeout=5)
            return response.status_code == 200
        except:
            return False
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        while time.time() - start_time < duration_seconds:
            executor.submit(send_request)
            requests_sent += 1
            time.sleep(0.01)  # 100 req/s
    
    print(f"Sent {requests_sent} requests in {duration_seconds}s")

# Ejecutar por 5 minutos
continuous_load(300)
```

4. Monitorea el escalado en otra terminal:
```bash
watch -n 2 'kubectl get hpa && echo "" && kubectl get pods -l app=iris-api'
```

**Preguntas:**
- ¿Cuánto tarda en escalar de 2 a 10 réplicas?
- ¿Cuándo empieza a bajar réplicas después de que baja la carga?
- ¿Qué pasa si el límite de recursos del nodo se alcanza?

---

### **Ejercicio 10: Implementar Data Drift Alerts**

**Objetivo:** Detectar drift automáticamente y enviar alertas.

**Tareas:**

1. Crea un nuevo notebook `02_drift_detection.ipynb`:

```python
import requests
import pandas as pd
import numpy as np
from sklearn.datasets import load_iris
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset
import os
from datetime import datetime

# Cargar datos de referencia
iris = load_iris()
df_reference = pd.DataFrame(iris.data, columns=[
    'sepal length (cm)', 'sepal width (cm)', 
    'petal length (cm)', 'petal width (cm)'
])

# Simular datos con drift (features alteradas)
def add_drift(df, drift_amount=0.5):
    """Agrega drift artificial a los datos"""
    df_drift = df.copy()
    df_drift['sepal length (cm)'] = df_drift['sepal length (cm)'] * (1 + drift_amount)
    df_drift['petal length (cm)'] = df_drift['petal length (cm)'] * (1 - drift_amount * 0.5)
    return df_drift

# Crear datos con diferentes niveles de drift
df_no_drift = df_reference.sample(50, random_state=42)
df_small_drift = add_drift(df_reference.sample(50, random_state=43), 0.2)
df_large_drift = add_drift(df_reference.sample(50, random_state=44), 0.8)

# Función para detectar drift
def detect_drift(reference_data, current_data, threshold=0.5):
    """Detecta drift y retorna métricas"""
    report = Report(metrics=[DataDriftPreset()])
    report.run(reference_data=reference_data, current_data=current_data)
    
    result = report.as_dict()
    drift_detected = result['metrics'][0]['result']['dataset_drift']
    drift_share = result['metrics'][0]['result']['share_of_drifted_columns']
    
    return {
        'drift_detected': drift_detected,
        'drift_share': drift_share,
        'alert': drift_share > threshold
    }

# Probar con diferentes niveles de drift
print("📊 Resultados de Detección de Drift:\n")

for name, data in [('No Drift', df_no_drift), 
                    ('Small Drift', df_small_drift), 
                    ('Large Drift', df_large_drift)]:
    result = detect_drift(df_reference, data)
    alert_icon = "🚨" if result['alert'] else "✅"
    print(f"{alert_icon} {name}:")
    print(f"   Drift Detected: {result['drift_detected']}")
    print(f"   Drift Share: {result['drift_share']:.2%}\n")
```

2. Expande el código para enviar alertas (simuladas):
```python
def send_alert(drift_info):
    """Simula envío de alerta (podrías integrar con Slack, email, etc)"""
    alert_message = f"""
    🚨 ALERTA DE DATA DRIFT DETECTADA
    
    Timestamp: {datetime.now().isoformat()}
    Drift Share: {drift_info['drift_share']:.2%}
    
    Acción recomendada: Revisar calidad de datos y considerar re-entrenamiento
    """
    print(alert_message)
    
    # Aquí podrías agregar:
    # - requests.post() a Slack webhook
    # - smtplib para enviar email
    # - Logging a un sistema de monitoreo

# Usar la función
result = detect_drift(df_reference, df_large_drift, threshold=0.3)
if result['alert']:
    send_alert(result)
```

**Bonus:** Integra con un webhook real de Slack o Discord.

---

### **Ejercicio 11: Implementar A/B Testing**

**Objetivo:** Desplegar dos versiones del modelo simultáneamente y comparar.

**Tareas:**

1. Crea dos versiones del modelo (ya tienes v1, crea v2 con algoritmo diferente)

2. Despliega ambas versiones con labels diferentes:

Modifica `infra/iris_api.tf` para crear dos deployments:

```hcl
# Model A (RandomForest)
resource "kubernetes_deployment" "iris_api_a" {
  metadata {
    name = "iris-api-a"
    labels = {
      app = "iris-api"
      version = "a"
    }
  }
  # ... spec con imagen iris-api:v1
}

# Model B (LogisticRegression)
resource "kubernetes_deployment" "iris_api_b" {
  metadata {
    name = "iris-api-b"
    labels = {
      app = "iris-api"
      version = "b"
    }
  }
  # ... spec con imagen iris-api:v2
}
```

3. Crea un service que distribuya tráfico 50/50:
```hcl
resource "kubernetes_service" "iris_api" {
  metadata {
    name = "iris-service"
  }
  spec {
    selector = {
      app = "iris-api"  # Selecciona AMBAS versiones
    }
    # ... resto de configuración
  }
}
```

4. En el notebook, implementa tracking de qué versión respondió:
```python
results_a = []
results_b = []

for i in range(100):
    response = requests.post(f"{IRIS_API_URL}/predict", json=payload)
    result = response.json()
    
    # Identificar versión por algún campo único
    if result['model_version'] == '1.0.0':
        results_a.append(result)
    else:
        results_b.append(result)

# Comparar métricas
df_a = pd.DataFrame(results_a)
df_b = pd.DataFrame(results_b)

print(f"Model A (v1.0.0): {len(results_a)} requests")
print(f"  Avg Confidence: {df_a['confidence'].mean():.3f}")

print(f"\nModel B (v2.0.0): {len(results_b)} requests")
print(f"  Avg Confidence: {df_b['confidence'].mean():.3f}")
```

**Preguntas:**
- ¿Cuál modelo tiene mejor performance?
- ¿Cómo implementarías un cambio gradual (10% → 50% → 100%)?
- ¿Qué métricas adicionales compararías?

---

### **Ejercicio 12: Persistent Storage para MLflow**

**Objetivo:** Evitar pérdida de datos al recrear el clúster.

**Tareas:**

1. Crea un PersistentVolume en Kind:

```yaml
# infra/mlflow-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mlflow-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/mlflow-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mlflow-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

2. Aplica el PV:
```bash
kubectl apply -f infra/mlflow-pv.yaml
```

3. Modifica `infra/mlflow.tf` para usar el PVC:
```hcl
spec {
  template {
    spec {
      volume {
        name = "mlflow-data"
        persistent_volume_claim {
          claim_name = "mlflow-pvc"
        }
      }
      
      container {
        # ... config existente ...
        
        volume_mount {
          name       = "mlflow-data"
          mount_path = "/mlflow"
        }
        
        args = [
          "server",
          "--host", "0.0.0.0",
          "--port", "5000",
          "--backend-store-uri", "sqlite:////mlflow/mlflow.db",
          "--default-artifact-root", "/mlflow/artifacts"
        ]
      }
    }
  }
}
```

4. Aplica cambios y verifica:
```bash
terraform apply
```

5. Ejecuta experimentos y verifica que persistan después de recrear el pod:
```bash
kubectl delete pod -l app=mlflow
# Espera a que se recree
kubectl get pods -w
# Verifica que los experimentos anteriores sigan ahí en http://localhost:30001
```

---

## 🎓 Proyectos Finales (Capstone)

### **Proyecto 1: Pipeline Completo de Re-entrenamiento**

**Objetivo:** Implementar un workflow completo de MLOps.

**Tareas:**
1. Detectar drift en producción
2. Si drift > threshold, trigger re-entrenamiento
3. Entrenar nuevo modelo con datos actualizados
4. Validar accuracy del nuevo modelo
5. Si accuracy > modelo actual, desplegar nueva versión
6. Registrar todo en MLflow

**Duración estimada:** 4-6 horas

---

### **Proyecto 2: Dashboard de Monitoreo en Tiempo Real**

**Objetivo:** Crear un dashboard interactivo para monitoreo.

**Stack sugerido:** Streamlit o Gradio

**Features:**
- Visualización de métricas en tiempo real
- Alertas de drift
- Comparación de modelos
- Distribución de predicciones
- Health checks de servicios

**Duración estimada:** 6-8 horas

---

### **Proyecto 3: Multi-Modelo Ensemble**

**Objetivo:** Desplegar múltiples modelos y combinar predicciones.

**Tareas:**
1. Entrenar 3 modelos diferentes (RF, SVM, LogReg)
2. Desplegar cada uno como servicio separado
3. Crear un servicio "ensemble" que:
   - Consulta a los 3 modelos
   - Combina predicciones (voting, weighted average)
   - Retorna predicción final
4. Comparar accuracy del ensemble vs modelos individuales

**Duración estimada:** 5-7 horas

---

## 📚 Recursos Adicionales

### **Documentación:**
- [Kubernetes Official Docs](https://kubernetes.io/docs/home/)
- [MLflow Documentation](https://www.mlflow.org/docs/latest/index.html)
- [Evidently AI Docs](https://docs.evidentlyai.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

### **Tutoriales:**
- [Kubernetes by Example](https://kubernetesbyexample.com/)
- [MLOps Best Practices](https://ml-ops.org/)

### **Herramientas:**
- [k9s](https://k9scli.io/) - Terminal UI para Kubernetes
- [kubectx/kubens](https://github.com/ahmetb/kubectx) - Context switching
- [stern](https://github.com/stern/stern) - Multi-pod log tailing

---

## ✅ Checklist de Progreso

Marca los ejercicios que completes:

**Básico:**
- [ ] Ejercicio 1: Explorar el Clúster
- [ ] Ejercicio 2: Modificar Réplicas
- [ ] Ejercicio 3: Modificar el Notebook
- [ ] Ejercicio 4: Probar el API Directamente

**Intermedio:**
- [ ] Ejercicio 5: Simular Alta Carga
- [ ] Ejercicio 6: Modificar el Modelo
- [ ] Ejercicio 7: Configurar Variables de Entorno
- [ ] Ejercicio 8: Health Checks Personalizados

**Avanzado:**
- [ ] Ejercicio 9: Horizontal Pod Autoscaler
- [ ] Ejercicio 10: Data Drift Alerts
- [ ] Ejercicio 11: A/B Testing
- [ ] Ejercicio 12: Persistent Storage

**Proyectos:**
- [ ] Proyecto 1: Pipeline de Re-entrenamiento
- [ ] Proyecto 2: Dashboard de Monitoreo
- [ ] Proyecto 3: Multi-Modelo Ensemble

---

## 💬 Preguntas y Soporte

Si tienes dudas o problemas con los ejercicios:
1. Revisa el archivo `TROUBLESHOOTING.md`
2. Consulta los logs: `kubectl logs <pod-name>`
3. Describe el recurso: `kubectl describe <resource> <name>`
4. Pregunta al instructor o en el foro del curso

---

**¡Éxito con los ejercicios!** 🚀

*Recuerda: El objetivo es experimentar y aprender. No te preocupes si algo no funciona a la primera, el debugging es parte fundamental del aprendizaje en MLOps.*

