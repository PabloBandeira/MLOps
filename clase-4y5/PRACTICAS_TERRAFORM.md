# 🎯 PRÁCTICAS DE TERRAFORM - Modificando Infraestructura en Vivo

## 📋 Objetivo
Aprender a modificar recursos de Kubernetes usando Terraform sin parar el cluster.

## 🔑 Conceptos Clave

### **¿Qué Estamos Desplegando?**

Terraform está gestionando estos recursos de **Kubernetes**:

| Tipo de Recurso | Cantidad | Descripción |
|-----------------|----------|-------------|
| Deployments | 4 | MLflow, Evidently, Iris API (2 réplicas), Workspace |
| Services | 4 | Acceso de red a cada deployment |
| ConfigMaps | 1 | Configuración de Evidently |

### **¿Cómo Funciona la Actualización?**

```
1. Modificas el .tf
    ↓
2. terraform plan (muestra el diff)
    ↓
3. terraform apply (aplica el cambio)
    ↓
4. Kubernetes hace Rolling Update
    ↓
5. El servicio sigue funcionando (zero downtime)
```

---

## 🧪 PRÁCTICA 1: Reducir Memoria de Evidently

### **Objetivo:** 
Demostrar cómo Terraform detecta cambios en recursos y Kubernetes recrea los pods.

### **Estado Actual:**
```yaml
# infra/evidently.tf (líneas 81-90)
resources {
  requests = {
    cpu    = "250m"
    memory = "512Mi"
  }
  limits = {
    cpu    = "500m"
    memory = "1Gi"        ← Vamos a cambiar esto
  }
}
```

### **Paso a Paso:**

#### 1️⃣ Ver el estado actual de los pods
```bash
kubectl get pods -l app=evidently
kubectl describe pod -l app=evidently | grep -A 5 "Limits:"
```

**Output esperado:**
```
Limits:
  cpu:     500m
  memory:  1Gi
Requests:
  cpu:     250m
  memory:  512Mi
```

---

#### 2️⃣ Modificar el archivo `infra/evidently.tf`

**Cambiar las líneas 86-89:**

```terraform
limits = {
  cpu    = "500m"
  memory = "256Mi"     # ← Cambiado de 1Gi a 256Mi
}
```

**También puedes cambiar el request:**
```terraform
requests = {
  cpu    = "250m"
  memory = "128Mi"     # ← Cambiado de 512Mi a 128Mi
}
```

---

#### 3️⃣ Ver el plan de Terraform

```bash
cd infra
terraform plan
```

**🔍 ¿Qué verás?**

Terraform mostrará un **diff** indicando que va a:
- ⚠️ **Modificar** el Deployment de Evidently
- 🔄 **Forzar reemplazo** del pod (porque los recursos cambiaron)

**Output esperado:**
```hcl
Terraform will perform the following actions:

  # kubernetes_deployment.evidently will be updated in-place
  ~ resource "kubernetes_deployment" "evidently" {
      ...
      ~ spec {
          ~ template {
              ~ spec {
                  ~ container {
                      ~ resources {
                          ~ limits = {
                              - memory = "1Gi" -> null
                              + memory = "256Mi"
                            }
                          ~ requests = {
                              - memory = "512Mi" -> null
                              + memory = "128Mi"
                            }
                        }
                    }
                }
            }
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**💡 Interpretación:**
- `~` significa "modificar"
- `-` significa "valor anterior"
- `+` significa "valor nuevo"
- `1 to change` = Se modificará 1 recurso

---

#### 4️⃣ Aplicar los cambios

```bash
terraform apply
```

Terraform preguntará:
```
Do you want to perform these actions?
```

Escribe `yes` y presiona Enter.

---

#### 5️⃣ Observar el Rolling Update en tiempo real

**En otra terminal, ejecuta:**
```bash
kubectl get pods -l app=evidently -w
```

**Verás algo como:**
```
NAME                         READY   STATUS    RESTARTS   AGE
evidently-6789abcdef-xyz12   1/1     Running   0          5m

# Después de apply:
evidently-6789abcdef-xyz12   1/1     Terminating   0          5m
evidently-9876fedcba-abc34   0/1     Pending       0          0s
evidently-9876fedcba-abc34   0/1     ContainerCreating   0          0s
evidently-9876fedcba-abc34   1/1     Running             0          3s
evidently-6789abcdef-xyz12   0/1     Terminating         0          5m
```

**🎯 Lo que está pasando:**
1. Kubernetes crea un nuevo pod con los nuevos límites
2. Espera a que esté `Running`
3. Solo entonces termina el pod viejo
4. **Zero downtime** ✅

---

#### 6️⃣ Verificar el cambio

```bash
kubectl describe pod -l app=evidently | grep -A 5 "Limits:"
```

**Deberías ver:**
```
Limits:
  cpu:     500m
  memory:  256Mi     ← ¡Cambió!
Requests:
  cpu:     250m
  memory:  128Mi     ← ¡Cambió!
```

---

### **🎓 Preguntas para los Alumnos:**

1. ¿Qué pasaría si Evidently no puede arrancar con solo 128Mi?
   - **R:** Kubernetes marca el pod como `CrashLoopBackOff` y mantiene el viejo pod corriendo.

2. ¿Podemos revertir el cambio?
   - **R:** Sí, solo cambia el `.tf` de vuelta y ejecuta `terraform apply`.

3. ¿Se pierden los datos de Evidently?
   - **R:** Sí, porque no tenemos volumen persistente. Esto es para DEV. En producción usarías PersistentVolumes.

---

## 🧪 PRÁCTICA 2: Escalar Horizontalmente Iris API

### **Objetivo:**
Aumentar la capacidad del servicio de predicción sin downtime.

### **Estado Actual:**
```terraform
# infra/iris_api.tf (línea 11)
replicas = 2
```

---

### **Paso a Paso:**

#### 1️⃣ Ver el estado actual
```bash
kubectl get pods -l app=iris-api
```

**Output:**
```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-abc123-xyz         1/1     Running   0          10m
iris-api-abc123-def         1/1     Running   0          10m
```

---

#### 2️⃣ Modificar `infra/iris_api.tf`

**Cambiar la línea 11:**
```terraform
replicas = 4    # ← Cambiado de 2 a 4
```

---

#### 3️⃣ Ver el plan
```bash
terraform plan
```

**Output esperado:**
```
  ~ resource "kubernetes_deployment" "iris_api" {
      ~ spec {
          ~ replicas = 2 -> 4
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

---

#### 4️⃣ Aplicar
```bash
terraform apply -auto-approve
```

---

#### 5️⃣ Observar el escalado
```bash
kubectl get pods -l app=iris-api -w
```

**Verás:**
```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-abc123-xyz         1/1     Running   0          10m
iris-api-abc123-def         1/1     Running   0          10m
iris-api-abc123-ghi         0/1     Pending       0          0s  ← Nuevo
iris-api-abc123-jkl         0/1     Pending       0          0s  ← Nuevo
iris-api-abc123-ghi         0/1     ContainerCreating   0          1s
iris-api-abc123-jkl         0/1     ContainerCreating   0          1s
iris-api-abc123-ghi         1/1     Running             0          4s
iris-api-abc123-jkl         1/1     Running             0          4s
```

**🎯 Ahora tienes 4 réplicas manejando el tráfico!**

---

#### 6️⃣ Probar el balanceo de carga

**Terminal 1 - Ver logs de todas las réplicas:**
```bash
kubectl logs -f -l app=iris-api --tail=0 --prefix
```

**¿Qué hace?**
- `-f` = Streaming en tiempo real (como `tail -f`)
- `-l app=iris-api` = Logs de TODOS los pods con esa etiqueta
- `--tail=0` = Solo logs nuevos, no históricos

**Terminal 2 - Hacer múltiples requests:**
```bash
WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')

for i in {1..20}; do
  kubectl exec $WORKSPACE_POD -- curl -s http://iris-service:8000/health > /dev/null
  echo "Request $i enviado"
  sleep 0.3
done
```

**¿Qué hace?**
1. Obtiene el nombre del pod de workspace
2. Ejecuta `curl` **dentro** del pod (no desde tu máquina)
3. Hace 20 requests al servicio de Iris
4. Espera 0.3 seg entre cada request

**Verás logs de diferentes pods en Terminal 1**, demostrando el **load balancing** de Kubernetes.

---

### **🎓 Preguntas para los Alumnos:**

1. ¿Cuándo escalarías horizontalmente?
   - **R:** Alto tráfico, necesidad de alta disponibilidad, redundancia.

2. ¿Qué pasaría si escalas a 0 réplicas?
   - **R:** El servicio queda inaccesible. Terraform destruye todos los pods.

3. ¿Puedes escalar solo con `kubectl` sin Terraform?
   - **R:** Sí (`kubectl scale`), pero Terraform perdería el estado. Siempre usa Terraform.

---

## 🧪 PRÁCTICA 3: Cambiar Variables de Entorno

### **Objetivo:**
Modificar configuración de la aplicación sin reconstruir la imagen.

### **Estado Actual:**
```terraform
# infra/workspace.tf (líneas 65-68)
env {
  name  = "IRIS_API_URL"
  value = "http://iris-service:8000"
}
```

---

### **Ejemplo de Cambio:**

**Agregar variable de logging:**
```terraform
env {
  name  = "IRIS_API_URL"
  value = "http://iris-service:8000"
}

env {
  name  = "LOG_LEVEL"
  value = "DEBUG"    # ← Nueva variable
}
```

**Aplicar:**
```bash
terraform plan
terraform apply
```

**Resultado:** El pod del workspace se recrea con la nueva variable de entorno.

---

## 📊 TABLA RESUMEN: ¿Qué Puedes Cambiar con Terraform?

| Recurso | Cambio | Archivo | Línea | Efecto |
|---------|--------|---------|-------|--------|
| **Memoria/CPU** | Limits/Requests | `evidently.tf` | 81-90 | Pod se recrea |
| **Réplicas** | Número de pods | `iris_api.tf` | 11 | Pods se agregan/eliminan |
| **Variables de Entorno** | ENV vars | `workspace.tf` | 65-68 | Pod se recrea |
| **Puertos NodePort** | Puerto externo | `mlflow.tf` | 83 | Service se modifica |
| **Imagen** | Tag de versión | `iris_api.tf` | 31 | Rolling update |
| **ConfigMap** | Configuración | `evidently.tf` | 14-24 | Deployment se recrea si montado |

---

## 🚫 ¿Qué NO Puedes Cambiar con este Setup?

| Recurso | Por Qué |
|---------|---------|
| **Modelo en Iris API** | Está "cocinado" en la imagen. Requiere rebuild. |
| **Clúster Kind** | Se crea manualmente antes de Terraform. |
| **Notebooks** | Se copian con `kubectl cp`, no gestionados por Terraform. |

---

## 💡 DEMO SUGERIDA PARA LA CLASE

### **Secuencia de 15 minutos:**

1. **Minuto 0-2:** Mostrar estado actual
   ```bash
   kubectl get all
   kubectl describe pod -l app=evidently | grep Limits -A 3
   ```

2. **Minuto 2-5:** Modificar `evidently.tf` (reducir memoria a 256Mi)
   ```bash
   cd infra
   terraform plan    # Mostrar el diff
   ```

3. **Minuto 5-7:** Aplicar cambios
   ```bash
   terraform apply
   ```
   En otra terminal: `kubectl get pods -l app=evidently -w`

4. **Minuto 7-10:** Escalar Iris API de 2 a 4 réplicas
   ```bash
   # Modificar iris_api.tf
   terraform plan
   terraform apply -auto-approve
   ```

5. **Minuto 10-12:** Probar balanceo de carga
   ```bash
   kubectl exec -it <workspace-pod> -- bash
   for i in {1..10}; do curl http://iris-service:8000/health; done
   ```

6. **Minuto 12-15:** Revertir cambios
   ```bash
   # Volver a valores originales
   terraform plan
   terraform apply
   ```

---

## 🎯 Conclusiones Pedagógicas

### **¿Qué Aprendieron?**

✅ **Infrastructure as Code** - La infra es versionable como el código  
✅ **Declarativo vs Imperativo** - Describes "qué" no "cómo"  
✅ **Zero Downtime** - Kubernetes hace rolling updates automáticamente  
✅ **State Management** - Terraform mantiene el estado real vs deseado  
✅ **Preview Changes** - `terraform plan` antes de `apply` es clave  

### **Diferencia Clave: DEV vs PROD**

| Aspecto | DEV (Kind) | PROD (EKS/GKE/AKS) |
|---------|------------|---------------------|
| Clúster | Se crea/destruye | Ya existe, se gestiona por separado |
| Terraform | Solo recursos K8s | Recursos K8s + RDS + S3 + etc |
| Imágenes | `kind load` | Registry (ECR/GCR/ACR) |
| Volúmenes | Efímeros | PersistentVolumes con respaldo |

---

## 📚 Recursos Adicionales

- [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [Kubernetes Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Resource Management in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## 🆘 Troubleshooting

### Problema: `Error: context deadline exceeded`
**Solución:** El pod nuevo no pudo arrancar. Revisa los límites de recursos.
```bash
kubectl describe pod -l app=evidently
kubectl logs -l app=evidently --previous
```

### Problema: Terraform muestra "no changes"
**Solución:** Asegúrate de guardar el archivo `.tf` después de editarlo.

### Problema: El pod viejo no termina
**Solución:** Puede haber conexiones activas. Espera o fuerza la terminación:
```bash
kubectl delete pod -l app=evidently
```

---

¡Éxito con las prácticas! 🚀

