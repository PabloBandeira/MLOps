# Clase 4: MLOps en Kubernetes con Kind y Terraform

## 📖 Descripción

Este módulo migra la arquitectura completa de MLOps de Docker Compose a **Kubernetes** usando **Kind** (Kubernetes in Docker) y **Terraform** como gestor de infraestructura.

Implementamos un **patrón inmutable** donde el modelo de Machine Learning se entrena durante la construcción de la imagen Docker, quedando "cocinado" dentro del contenedor, eliminando la necesidad de volúmenes compartidos.

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│              KIND CLUSTER (mlops-cluster)                   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   MLflow     │  │  Evidently   │  │  Iris API    │    │
│  │   :5000      │  │   :8000      │  │  :8000       │    │
│  │ (NodePort)   │  │ (NodePort)   │  │ (ClusterIP)  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────┐       │
│  │         Jupyter Workspace :8888                 │       │
│  │         (NodePort)                              │       │
│  └────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
        ↑
        │ NodePorts expuestos en tu laptop
        │
   localhost:30001 (MLflow)
   localhost:30002 (Evidently)
   localhost:30003 (Jupyter)
```

---

## 📦 Servicios

| Servicio | Tecnología | Puerto Interno | Puerto Externo | Tipo |
|----------|-----------|----------------|----------------|------|
| **MLflow** | MLflow Server | 5000 | 30001 | NodePort |
| **Evidently** | Evidently Service | 8000 | 30002 | NodePort |
| **Iris API** | FastAPI + Scikit-learn | 8000 | - | ClusterIP (2 réplicas) |
| **Workspace** | JupyterLab | 8888 | 30003 | NodePort |

---

## 🎯 Objetivos de Aprendizaje

1. ✅ Comprender la diferencia entre Docker Compose y Kubernetes
2. ✅ Gestionar infraestructura con Terraform (IaC)
3. ✅ Implementar el patrón inmutable en contenedores
4. ✅ Trabajar con servicios ClusterIP y NodePort
5. ✅ Usar DNS interno de Kubernetes para comunicación entre servicios
6. ✅ Escalar horizontalmente aplicaciones (réplicas)

---

## 🚀 Quick Start

### Prerrequisitos

- Docker Desktop
- Kind
- kubectl
- Terraform
- Python 3.9+

**Si no tienes estas herramientas, sigue la guía completa en [ONBOARDING.md](./ONBOARDING.md)**

---

### Despliegue Rápido

```bash
# 1. Construir imágenes
cd app_iris && docker build -t iris-api:latest . && cd ..
cd app_workspace && docker build -t workspace:latest . && cd ..

# 2. Crear clúster Kind
kind create cluster --name mlops-cluster --config infra/kind-config.yaml

# 3. Cargar imágenes al clúster
kind load docker-image iris-api:latest --name mlops-cluster
kind load docker-image workspace:latest --name mlops-cluster

# 4. Desplegar con Terraform
cd infra
terraform init
terraform apply -auto-approve

# 5. Esperar a que los pods estén listos
kubectl get pods -w
# Ctrl+C cuando todos estén en Running

# 6. Acceder a Jupyter
open http://localhost:30003
```

---

## 📁 Estructura del Proyecto

```
clase-4/
├── README.md                    # Este archivo
├── ONBOARDING.md                # Guía detallada paso a paso
├── INSTALL_CHOCOLATEY.md        # Instalación de Chocolatey (Windows)
├── .gitignore                   # Archivos a ignorar en Git
│
├── app_iris/                    # Servicio de inferencia
│   ├── Dockerfile               # Multi-stage: entrena modelo en build
│   ├── requirements.txt         # FastAPI, scikit-learn, pandas
│   ├── train.py                 # Script de entrenamiento
│   └── main.py                  # API FastAPI con endpoint /predict
│
├── app_workspace/               # Entorno Jupyter para el alumno
│   ├── Dockerfile               # JupyterLab + librerías científicas
│   └── requirements.txt         # pandas, numpy, requests, mlflow, evidently
│
├── notebooks/                   # Notebooks para el alumno
│   └── 01_simulacion.ipynb      # Simulación de tráfico y monitoreo
│
└── infra/                       # Infraestructura Terraform
    ├── kind-config.yaml         # Configuración del clúster Kind
    ├── provider.tf              # Providers: kind, kubernetes
    ├── cluster.tf               # Definición del clúster
    ├── mlflow.tf                # Deployment + Service de MLflow
    ├── evidently.tf             # Deployment + Service + ConfigMap
    ├── iris_api.tf              # Deployment + Service (2 réplicas)
    ├── workspace.tf             # Deployment + Service + VolumenMount
    ├── variables.tf             # Variables de configuración
    └── outputs.tf               # Outputs útiles (URLs, comandos)
```

---

## 🔧 Componentes Técnicos

### 1. Iris API (Patrón Inmutable)

**Dockerfile:**
```dockerfile
# Stage 1: Build - Entrena el modelo
FROM python:3.9-slim AS builder
COPY train.py requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
RUN python train.py  # <-- El modelo se crea aquí

# Stage 2: Runtime - Sirve el modelo
FROM python:3.9-slim
COPY --from=builder /app/model.joblib /app/
COPY main.py requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Ventajas:**
- ✅ Sin dependencias externas en runtime
- ✅ Sin volúmenes compartidos
- ✅ Imagen autosuficiente
- ✅ Reproducible y versionable

---

### 2. Workspace (Entorno del Alumno)

Contenedor con JupyterLab preconfigurado:
- pandas, numpy, requests
- mlflow (cliente)
- evidently (cliente)
- Sin token de autenticación (para simplicidad pedagógica)

---

### 3. Terraform (IaC)

Todos los recursos de Kubernetes se definen declarativamente:

```hcl
# Ejemplo: Deployment de Iris API
resource "kubernetes_deployment" "iris_api" {
  metadata {
    name = "iris-api"
  }
  spec {
    replicas = 2  # Alta disponibilidad
    selector {
      match_labels = {
        app = "iris-api"
      }
    }
    template {
      # ... spec del pod
    }
  }
}
```

---

## 🧪 Flujo de Trabajo del Alumno

### Paso 1: Levantar la infraestructura
```bash
terraform apply
```

### Paso 2: Abrir Jupyter Lab
```
http://localhost:30003
```

### Paso 3: Ejecutar notebook de simulación

El notebook `01_simulacion.ipynb` hace:

1. **Smoke Test**: Verifica conectividad con servicios
2. **Simulación**: Envía 50 predicciones al Iris API
3. **Monitoreo**: Registra métricas en MLflow y drift en Evidently

### Paso 4: Visualizar resultados

- **MLflow**: http://localhost:30001
- **Evidently**: http://localhost:30002

---

## 🌐 Comunicación entre Servicios (DNS de Kubernetes)

Dentro del clúster, los servicios se resuelven por nombre:

| Servicio | URL Interna |
|----------|-------------|
| MLflow | `http://mlflow-service:5000` |
| Evidently | `http://evidently-service:8000` |
| Iris API | `http://iris-service:8000` |

Kubernetes gestiona automáticamente el DNS interno.

---

## 📊 Ejemplo de Uso del API

### Desde tu laptop (si usas NodePort):
```bash
curl -X POST "http://localhost:30004/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

### Desde Jupyter (usando DNS interno):
```python
import requests

response = requests.post(
    "http://iris-service:8000/predict",
    json={
        "sepal_length": 5.1,
        "sepal_width": 3.5,
        "petal_length": 1.4,
        "petal_width": 0.2
    }
)
print(response.json())
# {'prediction': 0, 'prediction_label': 'setosa', 'model_version': '1.0.0'}
```

---

## 🔍 Comandos Útiles

### Kubernetes

```bash
# Ver todos los recursos
kubectl get all

# Ver logs de un servicio
kubectl logs -l app=iris-api --tail=50

# Escalar el Iris API a 5 réplicas
kubectl scale deployment iris-api --replicas=5

# Reiniciar un deployment
kubectl rollout restart deployment iris-api

# Port-forward (alternativa a NodePort)
kubectl port-forward service/mlflow-service 5000:5000
```

### Terraform

```bash
# Ver plan sin aplicar
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy

# Ver outputs
terraform output
```

### Kind

```bash
# Listar clústeres
kind get clusters

# Ver nodos del clúster
kubectl get nodes

# Eliminar clúster
kind delete cluster --name mlops-cluster
```

---

## 🐛 Troubleshooting

### Problema: Pods en estado `ImagePullBackOff`

**Causa:** La imagen no está cargada en Kind.

**Solución:**
```bash
kind load docker-image iris-api:latest --name mlops-cluster
kubectl rollout restart deployment iris-api
```

---

### Problema: No puedo acceder a los servicios en localhost

**Verificar:**
```bash
kubectl get services
# Verifica que los NodePort estén configurados (30001, 30002, 30003)
```

**Alternativa (port-forward):**
```bash
kubectl port-forward service/mlflow-service 5000:5000
```

---

### Problema: El modelo no está en el contenedor

**Verificar el build:**
```bash
# Reconstruir la imagen
cd app_iris
docker build -t iris-api:latest . --no-cache

# Verificar que model.joblib se creó durante el build
docker run --rm iris-api:latest ls -la /app/
```

---

## 🧹 Limpieza

### Eliminar infraestructura pero mantener el clúster:
```bash
cd infra
terraform destroy
```

### Eliminar el clúster completo:
```bash
kind delete cluster --name mlops-cluster
```

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Kubernetes](https://kubernetes.io/docs/)
- [Kind](https://kind.sigs.k8s.io/)
- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)

### Conceptos Clave
- **Pod**: La unidad más pequeña en K8s (uno o más contenedores)
- **Deployment**: Gestiona réplicas de Pods
- **Service**: Expone Pods en la red (ClusterIP, NodePort, LoadBalancer)
- **ConfigMap**: Configuración inyectada como variables o archivos

---

## 🎓 Diferencias con Docker Compose

| Aspecto | Docker Compose | Kubernetes |
|---------|----------------|------------|
| **Orquestación** | Básica (un solo host) | Avanzada (multi-nodo) |
| **Escalamiento** | Manual | Automático (HPA) |
| **Alta Disponibilidad** | No nativa | Sí (réplicas, health checks) |
| **Gestión** | docker-compose CLI | kubectl + IaC |
| **Producción** | No recomendado | Estándar de industria |

---

## ✅ Checklist de Entrega

Al finalizar esta práctica, deberías poder:

- [ ] Crear un clúster Kubernetes local con Kind
- [ ] Desplegar servicios usando Terraform
- [ ] Construir imágenes con el patrón inmutable
- [ ] Cargar imágenes a Kind
- [ ] Escalar deployments horizontalmente
- [ ] Acceder a servicios con NodePort
- [ ] Ejecutar notebooks en el workspace
- [ ] Enviar predicciones al Iris API
- [ ] Monitorear con MLflow y Evidently
- [ ] Leer logs con kubectl
- [ ] Destruir la infraestructura limpiamente

---

## 👥 Créditos

**Materia:** MLOps - Maestría en Ciencia de Datos  
**Clase:** 4 - Kubernetes con Kind y Terraform  
**Instructor:** [Tu Nombre]  
**Fecha:** 2025  

---

## 📝 Notas Finales

Este módulo es la base para:
- **Clase 5:** CI/CD con GitHub Actions
- **Clase 6:** Despliegue en la nube (EKS/GKE/AKS)
- **Clase 7:** Monitoring avanzado con Prometheus + Grafana

¡Éxito en tu práctica! 🚀

