# 🌐 Kubernetes Networking: ClusterIP, NodePort y DNS Interno

## 📚 Conceptos Fundamentales

---

## 1️⃣ **Tipos de Servicios en Kubernetes**

### **¿Qué es un Service?**

Un **Service** en Kubernetes es una abstracción que define un conjunto lógico de Pods y una política para acceder a ellos. Los Services permiten que los Pods sean descubiertos y accesibles, incluso cuando se crean o eliminan dinámicamente.

---

## 🔵 **ClusterIP** (Acceso Interno Solamente)

### **Definición:**
- Es el tipo de Service **por defecto** en Kubernetes
- Expone el Service en una **IP interna del clúster**
- **SOLO accesible desde dentro del clúster**
- No es accesible desde tu máquina local (localhost)

### **¿Cuándo usar ClusterIP?**
✅ Comunicación entre servicios **dentro** del clúster  
✅ Microservicios que no necesitan exponerse al exterior  
✅ Bases de datos, caches, servicios internos  

### **Ejemplo en nuestra arquitectura:**

```yaml
# Configuración (NO usada en nuestro caso, pero es el default)
apiVersion: v1
kind: Service
metadata:
  name: iris-service-internal
spec:
  type: ClusterIP  # ← Tipo por defecto
  selector:
    app: iris-api
  ports:
    - port: 8000
      targetPort: 8000
```

**Resultado:**
```
NAME                  TYPE        CLUSTER-IP      PORT(S)
iris-service-internal ClusterIP   10.96.237.44    8000/TCP
```

**Cómo acceder:**
- ✅ Desde otro pod: `http://iris-service-internal:8000`
- ❌ Desde localhost: `http://localhost:8000` → **NO funciona**

---

## 🟢 **NodePort** (Acceso Externo)

### **Definición:**
- Expone el Service en un **puerto específico** de cada nodo del clúster
- El puerto está en el rango **30000-32767** (por defecto)
- Accesible desde **fuera del clúster** (tu máquina local)
- Kubernetes mapea: `localhost:NodePort` → `ClusterIP:Port`

### **¿Cuándo usar NodePort?**
✅ Desarrollo y testing local  
✅ Acceso directo desde tu navegador  
✅ Clústeres pequeños (Kind, Minikube)  
❌ Producción en la nube (usar LoadBalancer o Ingress)

### **Ejemplos en nuestra arquitectura:**

```yaml
# MLflow Service
apiVersion: v1
kind: Service
metadata:
  name: mlflow-service
spec:
  type: NodePort  # ← Expuesto externamente
  selector:
    app: mlflow
  ports:
    - port: 5000        # Puerto interno del clúster
      targetPort: 5000  # Puerto del contenedor
      nodePort: 30001   # Puerto externo (localhost)
```

**Resultado en kubectl:**
```
NAME             TYPE       CLUSTER-IP      PORT(S)          AGE
mlflow-service   NodePort   10.96.144.231   5000:30001/TCP   17h
                                             ^^^^  ^^^^^^
                                          Interno Externo
```

**Cómo acceder:**
- ✅ Desde otro pod: `http://mlflow-service:5000`
- ✅ Desde localhost: `http://localhost:30001`
- ✅ Desde navegador: `http://localhost:30001`

---

## 🔄 **Comparación Visual**

### **ClusterIP (Interno)**
```
┌─────────────────────────────────────┐
│       Kubernetes Cluster            │
│                                     │
│  ┌─────────┐      ┌─────────┐     │
│  │  Pod A  │─────▶│Service B│     │
│  │(Python) │      │ClusterIP│     │
│  └─────────┘      └─────────┘     │
│                         │          │
│                         ▼          │
│                   ┌─────────┐     │
│                   │  Pod B  │     │
│                   │ (API)   │     │
│                   └─────────┘     │
│                                    │
└────────────────────────────────────┘
     ❌ localhost:8000 NO funciona
```

### **NodePort (Externo + Interno)**
```
┌─────────────────────────────────────┐
│       Kubernetes Cluster            │
│                                     │
│  ┌─────────┐      ┌─────────┐     │
│  │  Pod A  │─────▶│Service B│     │
│  │(Python) │      │NodePort │     │
│  └─────────┘      │30001    │     │
│                   └─────────┘     │
│                         │          │
│                         ▼          │
│                   ┌─────────┐     │
│                   │  Pod B  │     │
│                   │ (API)   │     │
│                   └─────────┘     │
│                         ▲          │
└─────────────────────────┼──────────┘
                          │
      ┌───────────────────┘
      │
┌─────▼──────┐
│  Browser   │  ✅ localhost:30001
│ (External) │
└────────────┘
```

---

## 📡 **DNS Interno de Kubernetes**

### **¿Qué es?**

Kubernetes incluye un **DNS interno** (CoreDNS) que permite que los Pods se descubran entre sí usando nombres en lugar de IPs.

### **Formato del DNS:**

```
<service-name>.<namespace>.svc.cluster.local
```

**Componentes:**
- `<service-name>`: Nombre del Service
- `<namespace>`: Namespace (por defecto: `default`)
- `svc.cluster.local`: Sufijo del clúster

### **Ejemplos en nuestro proyecto:**

#### **Nombre Completo (FQDN):**
```python
MLFLOW_URI = "http://mlflow-service.default.svc.cluster.local:5000"
```

#### **Nombre Corto (mismo namespace):**
```python
MLFLOW_URI = "http://mlflow-service:5000"  # ← Recomendado
```

Si estás en el mismo namespace (`default`), puedes usar solo el nombre del Service.

---

## 🎯 **Servicios en Nuestra Arquitectura**

### **Vista Completa:**

```bash
kubectl get services
```

```
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
evidently-service   NodePort    10.96.224.227   <none>        8000:30002/TCP   17h
iris-service        NodePort    10.96.237.44    <none>        8000:30004/TCP   17h
kubernetes          ClusterIP   10.96.0.1       <none>        443/TCP          17h
mlflow-service      NodePort    10.96.144.231   <none>        5000:30001/TCP   17h
workspace-service   NodePort    10.96.99.69     <none>        8888:30003/TCP   17h
```

### **Análisis por Service:**

#### **1. mlflow-service (NodePort)**
- **Cluster IP:** `10.96.144.231`
- **Puerto interno:** `5000`
- **Puerto externo:** `30001`
- **Acceso interno:** `http://mlflow-service:5000`
- **Acceso externo:** `http://localhost:30001`

#### **2. iris-service (NodePort)**
- **Cluster IP:** `10.96.237.44`
- **Puerto interno:** `8000`
- **Puerto externo:** `30004`
- **Acceso interno:** `http://iris-service:8000`
- **Acceso externo:** `http://localhost:30004`

#### **3. workspace-service (NodePort)**
- **Cluster IP:** `10.96.99.69`
- **Puerto interno:** `8888`
- **Puerto externo:** `30003`
- **Acceso interno:** `http://workspace-service:8888`
- **Acceso externo:** `http://localhost:30003` (JupyterLab)

#### **4. kubernetes (ClusterIP)**
- **Servicio interno** del API Server de Kubernetes
- Solo para comunicación interna del clúster
- No accesible desde fuera

---

## 💡 **Casos de Uso en Nuestro Proyecto**

### **Desde el Workspace (Pod interno):**

```python
# ✅ CORRECTO - Usar nombres DNS internos
MLFLOW_URI = "http://mlflow-service:5000"
IRIS_API_URI = "http://iris-service:8000"
EVIDENTLY_URI = "http://evidently-service:8000"

# ❌ INCORRECTO - localhost no funciona dentro del pod
MLFLOW_URI = "http://localhost:30001"  # NO llega al servicio
```

**¿Por qué?**  
Dentro del pod, `localhost` se refiere al **propio pod**, no al host. Debes usar el **DNS interno**.

---

### **Desde tu Navegador (Externo):**

```bash
# ✅ CORRECTO - Usar NodePorts
http://localhost:30001  # MLflow
http://localhost:30002  # Evidently
http://localhost:30003  # JupyterLab
http://localhost:30004  # Iris API

# ❌ INCORRECTO - Los nombres DNS internos no funcionan
http://mlflow-service:5000  # No resuelve fuera del clúster
```

**¿Por qué?**  
Los nombres DNS internos solo funcionan **dentro del clúster**. Desde fuera, usas `localhost` con el NodePort.

---

## 🔍 **Comandos Útiles para Debugging**

### **1. Probar DNS desde un Pod:**

```bash
# Entrar al workspace
kubectl exec -it $(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}') -- bash

# Dentro del pod:
# Probar resolución DNS
nslookup mlflow-service

# Probar conectividad
curl http://mlflow-service:5000/health

# Ver todas las variables de entorno de servicios
env | grep SERVICE
```

### **2. Ver endpoints de un Service:**

```bash
# Ver a qué Pods apunta un Service
kubectl get endpoints mlflow-service

# Ver detalles del Service
kubectl describe service mlflow-service
```

### **3. Probar desde fuera del clúster:**

```bash
# Probar NodePort
curl http://localhost:30001/health

# Ver logs del servicio
kubectl logs -l app=mlflow --tail=20
```

---

## 🎓 **Preguntas Frecuentes**

### **P1: ¿Por qué usar NodePort en lugar de ClusterIP?**
**R:** En nuestro caso (Kind local), necesitamos acceder desde el navegador a JupyterLab, MLflow y Evidently. NodePort nos permite hacerlo. En producción, usaríamos un **LoadBalancer** o **Ingress Controller**.

### **P2: ¿Puedo tener un Service que sea ClusterIP y NodePort a la vez?**
**R:** No directamente. Un Service solo puede ser de un tipo. Pero puedes crear múltiples Services apuntando a los mismos Pods.

### **P3: ¿Por qué el Iris API tiene NodePort si solo se usa internamente?**
**R:** Para poder probarlo directamente desde Postman/curl durante desarrollo. En producción, podría ser solo ClusterIP.

### **P4: ¿Qué pasa si cambio la IP del Pod?**
**R:** ¡No importa! El Service mantiene su IP estable y el DNS siempre funciona. Kubernetes actualiza automáticamente los endpoints.

### **P5: ¿Cómo sabe Kubernetes qué Pods están detrás de un Service?**
**R:** Por el **selector** (ej: `app: iris-api`). Todos los Pods con esa label automáticamente se agregan al Service.

---

## 🚀 **Ejercicios Prácticos**

### **Ejercicio 1: Verificar DNS**
```bash
# Desde el workspace, resolver todos los servicios
kubectl exec -it <workspace-pod> -- bash
for svc in mlflow-service iris-service evidently-service; do
  echo "Resolviendo $svc:"
  nslookup $svc
done
```

### **Ejercicio 2: Crear un Service ClusterIP**
```bash
# Cambiar iris-service de NodePort a ClusterIP
# Editar infra/iris_api.tf:
# type = "ClusterIP"  # Quitar el nodePort

terraform apply

# Probar:
# ✅ Funciona: desde workspace → http://iris-service:8000
# ❌ No funciona: desde browser → http://localhost:30004
```

### **Ejercicio 3: Load Balancing**
```bash
# Escalar a 3 réplicas
kubectl scale deployment iris-api --replicas=3

# Ver endpoints (debería mostrar 3 IPs)
kubectl get endpoints iris-service

# Hacer requests y ver en logs cuál replica responde
kubectl logs -f -l app=iris-api --tail=1
```

---

## 📖 **Recursos Adicionales**

- [Kubernetes Services Official Docs](https://kubernetes.io/docs/concepts/services-networking/service/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Service Types](https://kubernetes.io/docs/tutorials/kubernetes-basics/expose/expose-intro/)

---

## 🎯 **Resumen Ejecutivo**

| Concepto | Descripción | Acceso Interno | Acceso Externo |
|----------|-------------|----------------|----------------|
| **ClusterIP** | IP interna del clúster | ✅ `service:port` | ❌ No accesible |
| **NodePort** | Puerto en el nodo (30000-32767) | ✅ `service:port` | ✅ `localhost:nodePort` |
| **DNS Interno** | Resolución automática de nombres | ✅ Automático | ❌ No funciona fuera |

**Regla de oro:**
- 🏠 **Dentro del clúster:** Usa nombres DNS (`mlflow-service:5000`)
- 🌍 **Fuera del clúster:** Usa NodePorts (`localhost:30001`)

---

**Creado para Clase 4 - MLOps en Kubernetes** 🚀

