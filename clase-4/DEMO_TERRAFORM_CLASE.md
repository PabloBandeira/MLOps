# 🎬 PRÁCTICAS DE TERRAFORM - Modificando Infraestructura en Vivo

## ⏱️ Duración: 15 minutos

En esta práctica aprenderás a modificar recursos de Kubernetes usando Terraform sin parar el cluster.

---

## 📋 PRÁCTICA 1: Reducir Memoria de Evidently (7 min)

### **Objetivo:**
Cambiar los límites de memoria del servicio Evidently de 1GB a 256MB usando Terraform, observando cómo Kubernetes hace un rolling update sin downtime.

### **Configuración Previa:**

Abre **dos terminales**:

```bash
# Terminal 1 - Comandos principales
cd clase-4

# Terminal 2 - Watch de pods (déjalo corriendo para ver cambios en tiempo real)
kubectl get pods -w
```

---

### **PASO 1: Ver Estado Actual**

Primero verifica cuánta memoria está usando Evidently actualmente.

**Terminal 1:**
```bash
# Ver pods corriendo
kubectl get pods

# Ver límites de memoria actuales
kubectl describe pod -l app=evidently | grep -A 5 "Limits:"
```

**¿Qué verás?**
```
Limits:
  cpu:     500m
  memory:  1Gi     ← Actualmente 1GB
```

Evidently está usando 1GB de límite de memoria. Vamos a reducirlo a 256MB usando Terraform.

---

### **PASO 2: Modificar el Código de Terraform**

Abre el archivo `infra/evidently.tf` en tu editor.

**Buscar líneas 86-89:**
```terraform
limits = {
  cpu    = "500m"
  memory = "1Gi"        # ← Cambiar esto
}
```

**Cambiar a:**
```terraform
limits = {
  cpu    = "500m"
  memory = "256Mi"      # ← De 1Gi a 256Mi
}
```

**Guarda el archivo.**

**💡 Concepto:** Terraform es **declarativo**. Solo describes el estado deseado (256Mi), no los pasos para llegar ahí. Terraform calcula cómo hacerlo automáticamente.

---

### **PASO 3: Ver el Plan de Cambios**

Antes de aplicar cambios, siempre revisa qué va a hacer Terraform.

**Terminal 1:**
```bash
cd infra
terraform plan
```

**¿Qué verás en la salida?**

Terraform mostrará un **diff** similar a `git diff`:

```hcl
  ~ resource "kubernetes_deployment" "evidently" {
      ~ spec {
          ~ template {
              ~ spec {
                  ~ container {
                      ~ resources {
                          ~ limits = {
                              ~ "memory" = "1Gi" -> "256Mi"
                            }
                        }
                    }
                }
            }
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

**Símbolos importantes:**
- `~` = Modificación (no destruye, solo actualiza)
- `-` = Valor antiguo (1Gi)
- `+` = Valor nuevo (256Mi)
- `1 to change` = Se modificará 1 recurso

**💡 Concepto:** `terraform plan` es como un **dry-run**. Muestra QUÉ va a cambiar sin hacerlo. Siempre usa `plan` antes de `apply`.

---

### **PASO 4: Aplicar el Cambio**

Ahora aplica los cambios al cluster.

**Terminal 1:**
```bash
terraform apply
# Terraform preguntará: "Do you want to perform these actions?"
# Escribe: yes
```

**🔍 Observa el Terminal 2:**

Mientras `apply` se ejecuta, verás en el Terminal 2 (donde tienes `kubectl get pods -w`) cómo Kubernetes hace un **Rolling Update**:

```
NAME                         READY   STATUS    RESTARTS   AGE
evidently-6789abcdef-xyz12   1/1     Running   0          5m

# Después de apply:
evidently-6789abcdef-xyz12   1/1     Terminating        0  5m
evidently-9876fedcba-abc34   0/1     Pending            0  0s
evidently-9876fedcba-abc34   0/1     ContainerCreating  0  0s
evidently-9876fedcba-abc34   1/1     Running            0  3s  ← Nuevo pod listo
evidently-6789abcdef-xyz12   0/1     Terminating        0  5m  ← Viejo se elimina
```

**💡 Concepto - Rolling Update:**
1. Kubernetes crea un **nuevo pod** con los nuevos límites (256Mi)
2. Espera a que esté `Running` y pase los health checks
3. **Solo entonces** termina el pod viejo
4. **Zero downtime** ✅ - El servicio siempre tiene un pod activo

---

### **PASO 5: Verificar el Cambio**

Confirma que el cambio se aplicó correctamente.

**Terminal 1:**
```bash
kubectl describe pod -l app=evidently | grep -A 5 "Limits:"
```

**Deberías ver:**
```
Limits:
  cpu:     500m
  memory:  256Mi     ← ¡Cambió de 1Gi a 256Mi!
Requests:
  cpu:     250m
  memory:  512Mi
```

✅ **El cambio se aplicó sin parar el cluster. Esto es Infrastructure as Code en acción.**

---

## 📋 PRÁCTICA 2: Escalar Horizontalmente Iris API (5 min)

### **Objetivo:**
Aumentar la capacidad del servicio de predicción escalando de 2 a 4 réplicas sin downtime.

### **PASO 1: Ver Estado Actual**

Verifica cuántas réplicas tiene actualmente la API de Iris.

**Terminal 1:**
```bash
kubectl get pods -l app=iris-api
```

**Deberías ver 2 pods:**
```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-abc123-xyz         1/1     Running   0          10m
iris-api-abc123-def         1/1     Running   0          10m
```

La API de Iris tiene **2 réplicas**. Vamos a escalar a **4** para manejar más tráfico.

---

### **PASO 2: Modificar el Código**

Abre el archivo `infra/iris_api.tf` en tu editor.

**Buscar línea 11:**
```terraform
replicas = 2
```

**Cambiar a:**
```terraform
replicas = 4
```

**Guarda el archivo.**

---

### **PASO 3: Ver Plan y Aplicar**

**Terminal 1:**
```bash
terraform plan
# Verás: ~ replicas = 2 -> 4

terraform apply -auto-approve
```

**🔍 Observa el Terminal 2:**

Kubernetes creará **2 pods nuevos** sin tocar los existentes:

```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-abc123-xyz         1/1     Running   0          10m
iris-api-abc123-def         1/1     Running   0          10m
iris-api-abc123-ghi         0/1     Pending            0  0s  ← Nuevo
iris-api-abc123-jkl         0/1     Pending            0  0s  ← Nuevo
iris-api-abc123-ghi         0/1     ContainerCreating  0  1s
iris-api-abc123-jkl         0/1     ContainerCreating  0  1s
iris-api-abc123-ghi         1/1     Running            0  4s  ← Listo!
iris-api-abc123-jkl         1/1     Running            0  4s  ← Listo!
```

**💡 Concepto - Escalado Horizontal:** Los pods viejos siguen corriendo mientras los nuevos arrancan. **Alta disponibilidad** garantizada.

---

### **PASO 4: Probar Balanceo de Carga**

Ahora verifica que Kubernetes está distribuyendo el tráfico entre las 4 réplicas.

**Terminal 1 - Ver logs en tiempo real:**
```bash
kubectl logs -f -l app=iris-api --tail=0 --prefix
```

**¿Qué hace?**
- `-f` = follow (streaming en tiempo real)
- `-l app=iris-api` = Muestra logs de TODAS las réplicas (4 pods)
- `--tail=0` = Solo logs nuevos (no históricos)
- `--prefix` = Podes distinguir qué pod generó cada log.

Deja este comando corriendo. Verás logs de todos los pods de `iris-api`.

**Abre Terminal 3 - Hacer requests:**
```bash
WORKSPACE_POD=$(kubectl get pod -l app=workspace -o jsonpath='{.items[0].metadata.name}')

for i in {1..20}; do
  kubectl exec $WORKSPACE_POD -- curl -s http://iris-service:8000/health > /dev/null
  echo "Request $i enviado"
  sleep 0.3
done
```

**🔍 Observa el Terminal 1:**

Verás logs de **DIFERENTES pods** (nombres distintos):

```
iris-api-abc123-xyz  INFO: GET /health
iris-api-abc123-jkl  INFO: GET /health  ← Diferente pod
iris-api-abc123-def  INFO: GET /health  ← Diferente pod
iris-api-abc123-ghi  INFO: GET /health  ← Diferente pod
iris-api-abc123-xyz  INFO: GET /health  ← De vuelta al primero
```

**💡 Concepto - Load Balancing:** Kubernetes distribuye el tráfico automáticamente entre las 4 réplicas usando el Service. No necesitas configurar nada extra.

---

## 📋 PRÁCTICA 3: Revertir Cambios (3 min)

### **Objetivo:**
Demostrar que Terraform es declarativo: volver a los valores originales revierte la infraestructura.

### **PASO 1: Volver a Estado Original**

Edita los archivos de Terraform para volver a los valores iniciales:

**1. Abre `infra/evidently.tf` (línea 88):**
```terraform
memory = "1Gi"      # ← Volver a 1Gi
```

**2. Abre `infra/iris_api.tf` (línea 11):**
```terraform
replicas = 2        # ← Volver a 2 réplicas
```

Guarda ambos archivos.

---

### **PASO 2: Aplicar los Cambios**

**Terminal 1:**
```bash
terraform plan
# Verás que detecta los cambios EN REVERSA
# memory: 256Mi -> 1Gi
# replicas: 4 -> 2

terraform apply -auto-approve
```

**🔍 Observa el Terminal 2:**

Kubernetes reducirá las réplicas de Iris API a 2 y recreará el pod de Evidently con 1Gi.

**💡 Concepto - Estado Declarativo:** Terraform siempre busca **converger al estado declarado**. Si cambias el código, cambia la infraestructura. No importa la dirección del cambio.

---

## 🎯 CONCEPTOS CLAVE APRENDIDOS

### **1. Infrastructure as Code (IaC)**

La infraestructura es código:
- ✅ **Versionable** - Puedes usar Git para trackear cambios
- ✅ **Reproducible** - Mismo código = mismo resultado
- ✅ **Auditable** - Historial completo de quién cambió qué

### **2. Declarativo vs Imperativo**

**Imperativo (kubectl - manual):** Le dices CÓMO hacerlo paso a paso
```bash
kubectl scale deployment iris-api --replicas=4
kubectl set resources deployment evidently --limits=memory=256Mi
```

**Declarativo (Terraform):** Describes QUÉ quieres, Terraform calcula el cómo
```terraform
replicas = 4
memory = "256Mi"
```

### **3. Estado Deseado vs Estado Real**

Así funciona Terraform:

```
1. Lee los archivos .tf (estado deseado)
         ↓
2. Consulta el cluster (estado real)
         ↓
3. Calcula el delta (diferencia)
         ↓
4. Aplica solo los cambios necesarios
```

### **4. Zero Downtime Deployments**

Kubernetes hace **rolling updates** automáticamente:
- Crea pods nuevos
- Espera a que estén listos
- Solo entonces elimina los viejos
- El servicio **nunca se cae**

### **5. Plan Before Apply**

**Regla de oro:** Siempre usa `terraform plan` antes de `terraform apply`.

Es como un **dry-run** que muestra QUÉ va a cambiar sin hacerlo. Previene errores costosos.

---

## 📊 TABLA RESUMEN PARA PROYECTAR

| Acción | Comando | Efecto en K8s |
|--------|---------|---------------|
| Ver plan | `terraform plan` | Muestra cambios sin aplicar |
| Aplicar | `terraform apply` | Modifica recursos |
| Destruir | `terraform destroy` | Elimina todos los recursos |
| Ver estado | `terraform show` | Muestra estado actual |
| Ver outputs | `terraform output` | Muestra valores exportados |

---

## 🎓 PREGUNTAS DE AUTO-EVALUACIÓN

### **1. ¿Qué pasaría si Evidently no puede arrancar con 256Mi?**

<details>
<summary>Ver respuesta</summary>

Kubernetes marca el nuevo pod como `CrashLoopBackOff` y **mantiene el pod viejo corriendo**. El servicio no se cae.

Kubernetes es inteligente:
- Detecta que el pod nuevo no pasa los health checks
- No elimina el pod viejo hasta que el nuevo esté listo
- **Zero downtime garantizado**

</details>

---

### **2. ¿Cómo determinas cuántas réplicas necesitas?**

<details>
<summary>Ver respuesta</summary>

Depende del tráfico y la carga. Se usan:

**Métricas:**
- CPU y memoria promedio por pod
- Requests/segundo que maneja cada pod
- Latencia de respuesta

**Herramientas:**
- **Horizontal Pod Autoscaler (HPA)** - Escala automáticamente basado en CPU/memoria
- **Load testing** - Simula tráfico y mide capacidad
- **Monitoreo en producción** - Ajusta basado en patrones reales

**Regla general:** Siempre ten al menos 2 réplicas para alta disponibilidad.

</details>

---

### **3. ¿Puedo cambiar la infraestructura con `kubectl` directamente?**

<details>
<summary>Ver respuesta</summary>

**Técnicamente sí**, pero **NO deberías hacerlo**.

**Problema:** Terraform perdería sincronización con el estado real del cluster. La próxima vez que ejecutes `terraform apply`, podría revertir tus cambios manuales.

**Regla:**
- ✅ Usa `kubectl` para **leer** y **debuggear** (`get`, `describe`, `logs`)
- ✅ Usa `terraform` para **crear** y **modificar** recursos
- ⚠️ Solo usa `kubectl` para cambios en **emergencias**, y luego actualiza el código Terraform

</details>

---

### **4. ¿Qué diferencia hay entre `terraform plan` y `terraform apply`?**

<details>
<summary>Ver respuesta</summary>

**`terraform plan`:**
- Muestra QUÉ va a cambiar **sin hacerlo**
- Es un dry-run (simulación)
- No modifica nada en el cluster
- Útil para revisar cambios antes de aplicarlos

**`terraform apply`:**
- **Ejecuta** los cambios
- Modifica el cluster real
- Primero muestra el plan y pide confirmación (a menos que uses `-auto-approve`)

**Workflow recomendado:**
```bash
terraform plan    # Revisar cambios
terraform apply   # Aplicar si todo se ve bien
```

</details>

---

## 🚀 BONUS: Explorar el Estado de Terraform

Terraform mantiene un **archivo de estado** (`terraform.tfstate`) que guarda el estado real del cluster.

### **Ver recursos gestionados:**

```bash
cd infra

# Listar todos los recursos
terraform state list
```

**Salida:**
```
kubernetes_config_map.evidently_config
kubernetes_deployment.evidently
kubernetes_deployment.iris_api
kubernetes_deployment.mlflow
kubernetes_deployment.workspace
kubernetes_service.evidently
kubernetes_service.iris
kubernetes_service.mlflow
kubernetes_service.workspace
```

### **Ver detalle de un recurso:**

```bash
terraform state show kubernetes_deployment.evidently
```

### **Ver el state file (formato JSON):**

```bash
cat terraform.tfstate | jq '.resources[] | {type: .type, name: .name}'
```

**⚠️ IMPORTANTE:** Nunca edites `terraform.tfstate` manualmente. Terraform lo gestiona automáticamente.

---

## 🔧 TROUBLESHOOTING

### **Problema 1: Pod queda en `Pending`**

**Síntomas:**
```bash
kubectl get pods
# NAME           READY   STATUS    RESTARTS   AGE
# evidently-xxx  0/1     Pending   0          30s
```

**Diagnóstico:**
```bash
kubectl describe pod <pod-name>
```

**Causas comunes:**
- Límites de recursos muy altos (el nodo no tiene capacidad)
- Imagen no cargada en Kind
- Health checks fallando

---

### **Problema 2: Terraform dice "no changes"**

**Síntomas:**
```bash
terraform plan
# No changes. Your infrastructure matches the configuration.
```

**Soluciones:**
1. Verifica que guardaste el archivo `.tf` después de editarlo
2. Refresca el estado: `terraform refresh`
3. Verifica que estás en el directorio `infra/`

---

### **Problema 3: `apply` muy lento (> 2 min)**

**Causa:** Kubernetes espera que los health checks pasen antes de marcar el pod como listo.

**¿Es normal?** Sí, especialmente si:
- El pod tarda en arrancar
- Tiene readiness probes configurados
- La imagen es grande

**Ver qué está esperando:**
```bash
kubectl describe pod -l app=evidently
```

---

## ⚡ RESUMEN RÁPIDO

Si necesitas repasar los comandos principales:

### **Cambiar Memoria de Evidently:**
```bash
# 1. Editar infra/evidently.tf línea 88: 1Gi → 256Mi
# 2. Aplicar
cd infra
terraform plan
terraform apply

# 3. Verificar
kubectl describe pod -l app=evidently | grep Limits -A 3

# 4. Revertir (opcional)
# Editar evidently.tf línea 88: 256Mi → 1Gi
terraform apply
```

### **Escalar Iris API:**
```bash
# 1. Editar infra/iris_api.tf línea 11: replicas = 2 → 4
# 2. Aplicar
terraform plan
terraform apply -auto-approve

# 3. Verificar
kubectl get pods -l app=iris-api
```

---

## 📚 COMANDOS DE TERRAFORM MÁS USADOS

| Comando | Descripción |
|---------|-------------|
| `terraform init` | Inicializa Terraform (primera vez) |
| `terraform plan` | Muestra cambios sin aplicar (dry-run) |
| `terraform apply` | Aplica cambios al cluster |
| `terraform apply -auto-approve` | Aplica sin pedir confirmación |
| `terraform destroy` | Elimina todos los recursos |
| `terraform state list` | Lista recursos gestionados |
| `terraform state show <recurso>` | Muestra detalle de un recurso |
| `terraform refresh` | Sincroniza estado con cluster |

---

✅ **Has completado las prácticas de Terraform!** 

Ahora sabes cómo modificar infraestructura de Kubernetes de forma declarativa, reproducible y sin downtime. 🚀

