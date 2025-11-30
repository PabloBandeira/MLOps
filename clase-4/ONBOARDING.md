# 🚀 CLASE 4: MLOps en Kubernetes con Kind y Terraform

## 📋 Índice
1. [Introducción](#introducción)
2. [Prerrequisitos](#prerrequisitos)
3. [Instalación de Herramientas](#instalación-de-herramientas)
4. [Arquitectura del Sistema](#arquitectura-del-sistema)
5. [Paso a Paso](#paso-a-paso)
6. [Verificación](#verificación)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Introducción

Bienvenido a la Clase 4 de MLOps. En esta sesión migraremos toda nuestra arquitectura de MLOps de Docker Compose a **Kubernetes** usando:

- **Kind** (Kubernetes in Docker) - Clúster local
- **Terraform** - Infrastructure as Code
- **Patrón Inmutable** - Modelo "cocinado" en la imagen Docker

### ¿Qué vamos a lograr?

✅ Levantar un clúster Kubernetes local con Kind  
✅ Desplegar 4 servicios (MLflow, Evidently, Iris API, Jupyter Workspace)  
✅ Todo gestionado por Terraform (infraestructura declarativa)  
✅ **Cero instalación de Python en tu laptop** - todo en contenedores  

---

## 🔧 Prerrequisitos

### Lo que YA debes tener instalado:
- ✅ **Docker Desktop** (de las clases anteriores)
- ✅ **Python 3.9+** (solo para ejecutar scripts de instalación)

### Lo que vamos a instalar AHORA:
- 🆕 **Kind** - Kubernetes local
- 🆕 **kubectl** - CLI de Kubernetes
- 🆕 **Terraform** - Gestor de infraestructura

---

## 📦 Instalación de Herramientas

### Paso 1: Verificar Docker

```bash
docker --version
# Debe mostrar: Docker version 24.x.x o superior
```

Si Docker no está corriendo, inicia Docker Desktop.

---

### Paso 2: Instalar Kind

**macOS (con Homebrew):**
```bash
brew install kind
```

**macOS (sin Homebrew):**
```bash
# Descargar binario
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
# Para Intel Mac, usar: kind-darwin-amd64

# Dar permisos
chmod +x ./kind

# Mover a PATH
sudo mv ./kind /usr/local/bin/kind
```

**Verificar instalación:**
```bash
kind --version
# Debe mostrar: kind v0.20.0 o superior
```

---

### Paso 3: Instalar kubectl

**macOS (con Homebrew):**
```bash
brew install kubectl
```

**macOS (sin Homebrew):**
```bash
# Descargar binario
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"
# Para Intel Mac, cambiar arm64 por amd64

# Dar permisos
chmod +x ./kubectl

# Mover a PATH
sudo mv ./kubectl /usr/local/bin/kubectl
```

**Verificar instalación:**
```bash
kubectl version --client
# Debe mostrar la versión del cliente
```

---

### Paso 4: Instalar Terraform

**macOS (con Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**macOS (sin Homebrew):**
```bash
# Descargar binario (ARM)
curl -LO https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_darwin_arm64.zip

# Para Intel Mac:
# curl -LO https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_darwin_amd64.zip

# Descomprimir
unzip terraform_1.6.6_darwin_arm64.zip

# Mover a PATH
sudo mv terraform /usr/local/bin/

# Limpiar
rm terraform_1.6.6_darwin_arm64.zip
```

**Verificar instalación:**
```bash
terraform --version
# Debe mostrar: Terraform v1.6.x o superior
```

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                  KIND CLUSTER (mlops-cluster)               │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   MLflow     │  │  Evidently   │  │  Iris API    │    │
│  │   Server     │  │   Service    │  │  (FastAPI)   │    │
│  │              │  │              │  │  2 réplicas  │    │
│  │ NodePort     │  │ NodePort     │  │ ClusterIP    │    │
│  │ 30001:5000   │  │ 30002:8000   │  │ 8000         │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────┐       │
│  │         Jupyter Workspace (Tu entorno)         │       │
│  │  - pandas, numpy, requests, mlflow, evidently  │       │
│  │  - NodePort 30003:8888                         │       │
│  │  - Notebooks montados desde /notebooks         │       │
│  └────────────────────────────────────────────────┘       │
│                                                             │
│         Red interna: mlops-network                         │
└─────────────────────────────────────────────────────────────┘
```

### Puertos Expuestos (acceso desde tu laptop):

| Servicio | Puerto Local | Puerto en Kubernetes | Acceso |
|----------|--------------|---------------------|---------|
| MLflow | 5000 | NodePort 30001 | http://localhost:30001 |
| Evidently | 8000 | NodePort 30002 | http://localhost:30002 |
| Jupyter | 8888 | NodePort 30003 | http://localhost:30003 |
| Iris API | 8000 | ClusterIP (interno) | http://iris-service:8000 |

---

## 🚦 Paso a Paso

### Paso 1: Navegar al directorio de la clase

```bash
cd /Users/pablo/Desktop/MLops/clase-4
```

---

### Paso 2: Construir las imágenes Docker

#### 2.1 Construir la API de Iris (con modelo entrenado)

```bash
cd app_iris
docker build -t iris-api:latest .
cd ..
```

**🔍 ¿Qué hace este build?**
Durante la construcción, se ejecuta `train.py` que:
- Carga el dataset Iris
- Entrena un RandomForestClassifier
- Guarda `model.joblib` dentro de la imagen
- El modelo queda "cocinado" y listo para servir

#### 2.2 Construir el Workspace Jupyter

```bash
cd app_workspace
docker build -t workspace:latest .
cd ..
```

---

### Paso 3: Crear el clúster Kind

```bash
kind create cluster --name mlops-cluster --config infra/kind-config.yaml
```

**Verificar que el clúster esté corriendo:**
```bash
kubectl cluster-info --context kind-mlops-cluster
```

Deberías ver algo como:
```
Kubernetes control plane is running at https://127.0.0.1:xxxxx
```

---

### Paso 4: Cargar las imágenes al clúster Kind

Kind no tiene acceso a tu registro local de Docker, debemos cargar las imágenes:

```bash
# Cargar imagen de Iris API
kind load docker-image iris-api:latest --name mlops-cluster

# Cargar imagen de Workspace
kind load docker-image workspace:latest --name mlops-cluster
```

**Verificar que se cargaron:**
```bash
docker exec -it mlops-cluster-control-plane crictl images | grep -E "iris-api|workspace"
```

---

### Paso 5: Desplegar la infraestructura con Terraform

```bash
cd infra

# Inicializar Terraform (solo la primera vez)
terraform init

# Ver el plan de ejecución (opcional)
terraform plan

# Aplicar la infraestructura
terraform apply
```

Cuando te pregunte "Do you want to perform these actions?", escribe `yes` y presiona Enter.

**⏱️ Esto tomará 1-2 minutos.**

---

### Paso 6: Esperar a que todos los pods estén listos

```bash
kubectl get pods -w
```

Espera hasta que todos los pods muestren `Running` y `1/1` o `2/2` en READY:

```
NAME                          READY   STATUS    RESTARTS   AGE
mlflow-xxxxxxxxx-xxxxx        1/1     Running   0          30s
evidently-xxxxxxxxx-xxxxx     1/1     Running   0          30s
iris-api-xxxxxxxxx-xxxxx      1/1     Running   0          30s
iris-api-xxxxxxxxx-yyyyy      1/1     Running   0          30s
workspace-xxxxxxxxx-xxxxx     1/1     Running   0          30s
```

Presiona `Ctrl+C` para salir del modo watch.

---

## ✅ Verificación

### 1️⃣ Verificar servicios

```bash
kubectl get services
```

Deberías ver algo como:

```
NAME               TYPE        CLUSTER-IP      PORT(S)          AGE
mlflow-service     NodePort    10.96.x.x       5000:30001/TCP   1m
evidently-service  NodePort    10.96.x.x       8000:30002/TCP   1m
iris-service       ClusterIP   10.96.x.x       8000/TCP         1m
workspace-service  NodePort    10.96.x.x       8888:30003/TCP   1m
```

---

### 2️⃣ Acceder a las interfaces web

Abre tu navegador y visita:

**MLflow UI:**
```
http://localhost:30001
```

**Evidently UI:**
```
http://localhost:30002
```

**Jupyter Lab:**
```
http://localhost:30003
```

---

### 3️⃣ Ejecutar la simulación

1. Abre Jupyter Lab: http://localhost:30003
2. Ve a la carpeta `notebooks/`
3. Abre el notebook `01_simulacion.ipynb`
4. Ejecuta todas las celdas (`Run` → `Run All Cells`)

El notebook hará:
- ✅ Test de conectividad con MLflow y Iris API
- ✅ Envío de 50 predicciones
- ✅ Generación de reporte de drift en Evidently

---

### 4️⃣ Verificar resultados

**En MLflow (http://localhost:30001):**
- Verás un experimento llamado "iris-predictions"
- Con métricas de las predicciones realizadas

**En Evidently (http://localhost:30002):**
- Verás un proyecto "iris-monitoring"
- Con reportes de Data Quality y Data Drift

---

## 🔍 Comandos Útiles

### Ver logs de un pod:
```bash
# Listar pods
kubectl get pods

# Ver logs (reemplaza POD_NAME)
kubectl logs POD_NAME

# Seguir logs en tiempo real
kubectl logs -f POD_NAME
```

### Reiniciar un deployment:
```bash
kubectl rollout restart deployment iris-api
```

### Entrar a un pod (para debugging):
```bash
kubectl exec -it POD_NAME -- /bin/bash
```

### Ver descripción completa de un recurso:
```bash
kubectl describe pod POD_NAME
kubectl describe service SERVICE_NAME
```

---

## 🐛 Troubleshooting

### Problema: El pod está en `Pending` o `ImagePullBackOff`

**Causa:** La imagen no está cargada en Kind.

**Solución:**
```bash
# Cargar nuevamente la imagen
kind load docker-image iris-api:latest --name mlops-cluster
kind load docker-image workspace:latest --name mlops-cluster

# Reiniciar el deployment
kubectl rollout restart deployment iris-api
kubectl rollout restart deployment workspace
```

---

### Problema: No puedo acceder a los servicios en localhost:30001

**Verificar que el servicio esté en NodePort:**
```bash
kubectl get service mlflow-service -o yaml | grep nodePort
```

**Verificar port-forward (alternativa):**
```bash
# Si NodePort no funciona, usar port-forward
kubectl port-forward service/mlflow-service 5000:5000
```

---

### Problema: Jupyter no muestra los notebooks

**Verificar el volumen:**
```bash
kubectl describe pod -l app=workspace | grep -A 5 Volumes
```

**Verificar que la ruta local sea correcta:**
El volumen debe apuntar a `/Users/pablo/Desktop/MLops/clase-4/notebooks`

---

### Problema: La API de Iris devuelve 404 o 500

**Ver logs del pod:**
```bash
kubectl logs -l app=iris-api --tail=50
```

**Verificar que el modelo esté cargado:**
```bash
# Entrar al pod
kubectl exec -it $(kubectl get pod -l app=iris-api -o jsonpath='{.items[0].metadata.name}') -- ls -la /app/

# Deberías ver model.joblib
```

---

### Problema: Terraform falla con "connection refused"

**Causa:** El cluster de Kind no está levantado o kubectl no está configurado.

**Solución:**
```bash
# Verificar que Kind esté corriendo
kind get clusters

# Verificar contexto de kubectl
kubectl config current-context
# Debe mostrar: kind-mlops-cluster

# Si no, cambiar contexto
kubectl config use-context kind-mlops-cluster
```

---

## 🧹 Limpieza (al terminar la práctica)

### Destruir la infraestructura (pero mantener el cluster):
```bash
cd infra
terraform destroy
```

### Eliminar el clúster Kind:
```bash
kind delete cluster --name mlops-cluster
```

### Limpiar imágenes Docker (opcional):
```bash
docker rmi iris-api:latest workspace:latest
```

---

## 📚 Conceptos Clave de esta Clase

### 1. **Patrón Inmutable**
El modelo se entrena durante el `docker build` y queda "cocinado" en la imagen. No necesitamos volúmenes compartidos para pasar el modelo entre servicios.

### 2. **Infrastructure as Code (IaC)**
Toda la infraestructura se define en archivos `.tf` de Terraform. Es versionable, reproducible y auditable.

### 3. **Kubernetes DNS**
Los servicios se comunican por nombres internos:
- `http://mlflow-service:5000`
- `http://iris-service:8000`
- `http://evidently-service:8000`

### 4. **NodePort vs ClusterIP**
- **NodePort:** Expone el servicio en un puerto del nodo (acceso desde tu laptop)
- **ClusterIP:** Solo accesible dentro del clúster (para comunicación interna)

### 5. **Workspace como "Entorno del Alumno"**
Todo el código Python se ejecuta dentro del contenedor Jupyter. Tu laptop solo necesita Docker + Kind + Terraform.

---

## 🎓 Próximos Pasos

Una vez que completes esta práctica, estarás listo para:

1. **Escalar horizontalmente** - Aumentar réplicas del Iris API
2. **Implementar Ingress** - Tener un único punto de entrada
3. **Agregar autoscaling** - HPA (Horizontal Pod Autoscaler)
4. **Migrar a la nube** - EKS (AWS), GKE (Google), AKS (Azure)

---

## 🆘 ¿Necesitas ayuda?

Si tienes problemas:

1. Revisa la sección de [Troubleshooting](#troubleshooting)
2. Verifica los logs: `kubectl logs -l app=NOMBRE_APP`
3. Revisa el estado de los pods: `kubectl describe pod POD_NAME`
4. Consulta con tu instructor

---

## 📝 Notas Finales

- **Tiempo estimado:** 30-45 minutos
- **Prerrequisitos:** Haber completado Clases 1-3
- **Complejidad:** Media-Alta
- **¿Qué aprendiste?** Migración de Docker Compose a Kubernetes con IaC

¡Éxito en tu práctica! 🚀

