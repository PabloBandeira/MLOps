# 👨‍🏫 Guía del Instructor - Clase 4

## 📋 Información General

**Clase:** 4 - Migración a Kubernetes con Kind y Terraform  
**Duración:** 2-3 horas  
**Nivel:** Intermedio-Avanzado  
**Prerrequisitos:** Clases 1-3 (Docker y Docker Compose)

---

## 🎯 Objetivos de Aprendizaje

### Conceptuales
- [ ] Comprender las diferencias fundamentales entre Docker Compose y Kubernetes
- [ ] Entender el concepto de Infrastructure as Code (IaC)
- [ ] Conocer el patrón inmutable en contenedores
- [ ] Comprender el DNS interno de Kubernetes
- [ ] Entender el concepto de alta disponibilidad con réplicas

### Técnicos
- [ ] Instalar y configurar Kind, kubectl y Terraform
- [ ] Crear un clúster Kubernetes local
- [ ] Desplegar aplicaciones usando Terraform
- [ ] Trabajar con Services (ClusterIP, NodePort)
- [ ] Escalar deployments horizontalmente
- [ ] Leer logs y diagnosticar problemas con kubectl

---

## 📚 Material Entregado

### Documentación
- ✅ `COMIENZA_AQUI.txt` - Punto de entrada
- ✅ `ONBOARDING.md` - Guía paso a paso completa
- ✅ `README.md` - Visión general del proyecto
- ✅ `ARCHITECTURE.md` - Diagramas y arquitectura técnica
- ✅ `QUICK_REFERENCE.md` - Comandos útiles y troubleshooting

### Código
- ✅ `app_iris/` - API FastAPI con modelo "cocinado"
- ✅ `app_workspace/` - Jupyter Lab con todas las dependencias
- ✅ `notebooks/01_simulacion.ipynb` - Práctica guiada
- ✅ `infra/` - Archivos Terraform completos
- ✅ `scripts/` - Scripts de automatización

---

## ⏱️ Plan de Clase Sugerido

### Bloque 1: Introducción (20 min)

**Objetivos:**
- Contextualizar la migración de Docker Compose a Kubernetes
- Explicar por qué Kubernetes en producción

**Actividades:**
1. **Repaso de Clases Anteriores (5 min)**
   - Arquitectura con Docker Compose
   - Limitaciones en producción

2. **Introducción a Kubernetes (10 min)**
   - ¿Qué es Kubernetes?
   - Conceptos básicos: Pods, Deployments, Services
   - Diferencias con Docker Compose

3. **Introducción a Terraform (5 min)**
   - ¿Qué es Infrastructure as Code?
   - Ventajas de Terraform
   - Flujo de trabajo: init → plan → apply

**Materiales de apoyo:**
- Diagrama en `ARCHITECTURE.md`
- Tabla comparativa en `README.md`

---

### Bloque 2: Setup (30 min)

**Objetivos:**
- Instalar todas las herramientas necesarias
- Verificar que el entorno está listo

**Actividades:**
1. **Verificación de Prerrequisitos (5 min)**
   ```bash
   ./scripts/check-prerequisites.sh
   ```

2. **Instalación de Herramientas (15 min)**
   - Instalación de Kind
   - Instalación de kubectl
   - Instalación de Terraform
   
   **💡 Tip para el Instructor:**
   - Tener un Plan B si hay problemas de red (USBs con instaladores)
   - Ayudar a alumnos con Windows o Linux si los hay

3. **Build de Imágenes (10 min)**
   ```bash
   cd app_iris
   docker build -t iris-api:latest .
   cd ../app_workspace
   docker build -t workspace:latest .
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar el multi-stage build
   - Mostrar que el modelo se entrena durante el build
   - Verificar que `model.joblib` está en la imagen

---

### Bloque 3: Despliegue con Terraform (40 min)

**Objetivos:**
- Crear el clúster Kind
- Desplegar toda la infraestructura con Terraform
- Entender el código de Terraform

**Actividades:**
1. **Crear Clúster Kind (10 min)**
   ```bash
   kind create cluster --name mlops-cluster --config infra/kind-config.yaml
   ```
   
   **💡 Puntos de Enseñanza:**
   - Explicar el archivo `kind-config.yaml`
   - Mostrar los port mappings
   - Verificar con `kubectl cluster-info`

2. **Cargar Imágenes (5 min)**
   ```bash
   kind load docker-image iris-api:latest --name mlops-cluster
   kind load docker-image workspace:latest --name mlops-cluster
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar por qué Kind no tiene acceso directo al Docker local
   - Mostrar con `docker exec -it mlops-cluster-control-plane crictl images`

3. **Revisión de Código Terraform (15 min)**
   - Abrir `infra/provider.tf` - Explicar providers
   - Abrir `infra/mlflow.tf` - Explicar Deployment + Service
   - Abrir `infra/iris_api.tf` - Explicar réplicas
   - Mostrar variables en `variables.tf`

4. **Aplicar Terraform (10 min)**
   ```bash
   cd infra
   terraform init
   terraform plan  # Mostrar el plan
   terraform apply
   ```
   
   **💡 Puntos de Enseñanza:**
   - Explicar qué hace `terraform init`
   - Revisar el plan antes de aplicar
   - Esperar a que los pods estén listos

---

### Bloque 4: Exploración de Kubernetes (30 min)

**Objetivos:**
- Familiarizarse con kubectl
- Explorar los recursos creados
- Entender el DNS interno

**Actividades:**
1. **Ver Recursos (10 min)**
   ```bash
   kubectl get pods
   kubectl get services
   kubectl get deployments
   kubectl describe pod <POD_NAME>
   ```
   
   **💡 Puntos de Enseñanza:**
   - Explicar los estados de los pods (Running, Pending, etc.)
   - Mostrar las columnas READY (2/2 significa 2 réplicas)
   - Explicar los tipos de Service (NodePort, ClusterIP)

2. **Ver Logs (5 min)**
   ```bash
   kubectl logs -l app=iris-api
   kubectl logs -f <POD_NAME>  # Follow
   ```

3. **Acceder a las UIs (10 min)**
   - Abrir http://localhost:30001 (MLflow)
   - Abrir http://localhost:30002 (Evidently)
   - Abrir http://localhost:30003 (Jupyter)
   - Abrir http://localhost:30004 (Iris API)

4. **Test de DNS Interno (5 min)**
   ```bash
   kubectl exec -it <WORKSPACE_POD> -- bash
   curl http://mlflow-service:5000/health
   curl http://iris-service:8000/health
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar cómo funciona el DNS de Kubernetes
   - Mostrar que no necesitas IPs, solo nombres de servicio

---

### Bloque 5: Práctica Guiada (40 min)

**Objetivos:**
- Ejecutar el notebook de simulación
- Enviar predicciones al API
- Visualizar resultados en MLflow y Evidently

**Actividades:**
1. **Abrir Jupyter Lab (5 min)**
   - Navegar a http://localhost:30003
   - Abrir `notebooks/01_simulacion.ipynb`

2. **Ejecutar Notebook (25 min)**
   - Ejecutar celda por celda explicando cada paso:
     - Smoke tests
     - Carga de datos
     - Envío de predicciones
     - Registro en MLflow
     - Generación de reporte Evidently

3. **Revisión de Resultados (10 min)**
   - Abrir MLflow: ver experimentos y métricas
   - Abrir Evidently: ver reporte de drift
   - Discutir los resultados

---

### Bloque 6: Experimentación (30 min)

**Objetivos:**
- Practicar comandos de Kubernetes
- Experimentar con escalamiento
- Simular fallos y recuperación

**Actividades:**
1. **Escalar el Iris API (10 min)**
   ```bash
   # Escalar a 5 réplicas
   kubectl scale deployment iris-api --replicas=5
   
   # Ver el escalamiento en tiempo real
   kubectl get pods -w
   
   # Verificar que todas las réplicas están listas
   kubectl get deployment iris-api
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar que Kubernetes automáticamente balancea el tráfico
   - Mostrar que no se pierde ninguna petición durante el escalamiento

2. **Simular Fallo de un Pod (10 min)**
   ```bash
   # Eliminar un pod
   kubectl delete pod <POD_NAME>
   
   # Observar que Kubernetes lo recrea automáticamente
   kubectl get pods -w
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar self-healing de Kubernetes
   - Mostrar que el Deployment mantiene el número deseado de réplicas

3. **Ver Uso de Recursos (5 min)**
   ```bash
   kubectl top pods  # Requiere metrics-server (opcional)
   kubectl describe pod <POD_NAME>  # Ver resources
   ```

4. **Rolling Update (5 min)**
   ```bash
   kubectl rollout restart deployment iris-api
   kubectl rollout status deployment iris-api
   ```
   
   **💡 Punto de Enseñanza:**
   - Explicar rolling updates (zero downtime)
   - Mostrar que las réplicas se actualizan una por una

---

### Bloque 7: Conclusiones y Limpieza (10 min)

**Objetivos:**
- Resumir conceptos clave
- Limpiar recursos
- Asignar tareas para casa

**Actividades:**
1. **Resumen de Conceptos (5 min)**
   - Patrón inmutable
   - DNS de Kubernetes
   - Alta disponibilidad con réplicas
   - IaC con Terraform

2. **Limpieza (5 min)**
   ```bash
   cd infra
   terraform destroy
   kind delete cluster --name mlops-cluster
   ```

3. **Tareas Opcionales**
   - Modificar el número de réplicas en Terraform
   - Agregar un nuevo servicio
   - Implementar PersistentVolumeClaims
   - Explorar Helm Charts

---

## 🐛 Troubleshooting Común

### Problema 1: Docker daemon no está corriendo

**Síntoma:**
```
Cannot connect to the Docker daemon
```

**Solución:**
- Iniciar Docker Desktop
- Verificar con `docker ps`

---

### Problema 2: Kind falla al crear el clúster

**Síntoma:**
```
ERROR: failed to create cluster
```

**Solución:**
- Verificar que Docker tenga suficiente RAM (8 GB recomendado)
- Eliminar clústeres previos: `kind delete cluster --name mlops-cluster`
- Reintentar

---

### Problema 3: Pods en estado ImagePullBackOff

**Síntoma:**
```
NAME                        READY   STATUS             RESTARTS   AGE
iris-api-xxxxx-xxxxx        0/1     ImagePullBackOff   0          2m
```

**Solución:**
```bash
# Recargar imagen
kind load docker-image iris-api:latest --name mlops-cluster

# Reiniciar deployment
kubectl rollout restart deployment iris-api
```

---

### Problema 4: No se puede acceder a localhost:30001

**Síntoma:**
- El navegador no carga la página

**Solución:**
```bash
# Verificar que el servicio está en NodePort
kubectl get service mlflow-service

# Verificar port mappings del clúster
docker ps | grep mlops-cluster

# Alternativa: usar port-forward
kubectl port-forward service/mlflow-service 5000:5000
```

---

### Problema 5: Terraform falla con "connection refused"

**Síntoma:**
```
Error: Kubernetes cluster unreachable
```

**Solución:**
```bash
# Verificar que el clúster está corriendo
kind get clusters

# Verificar contexto de kubectl
kubectl config current-context

# Debe mostrar: kind-mlops-cluster
# Si no, cambiar:
kubectl config use-context kind-mlops-cluster

# Reintentar terraform
terraform apply
```

---

## 📊 Evaluación

### Criterios de Éxito
- [ ] Todos los pods están en estado Running
- [ ] Se puede acceder a las 4 UIs desde el navegador
- [ ] El notebook se ejecuta sin errores
- [ ] Las predicciones aparecen en MLflow
- [ ] El reporte de Evidently se genera correctamente

### Preguntas de Comprensión
1. ¿Qué ventajas tiene Kubernetes sobre Docker Compose?
2. ¿Qué es un Service en Kubernetes y qué tipos existen?
3. ¿Cómo funciona el DNS interno de Kubernetes?
4. ¿Qué es el patrón inmutable y por qué es útil?
5. ¿Qué hace Terraform en este proyecto?

### Ejercicio Adicional (Opcional)
- Modificar `infra/iris_api.tf` para tener 3 réplicas
- Aplicar el cambio con `terraform apply`
- Verificar que las 3 réplicas están corriendo
- Enviar 100 predicciones y observar el balanceo de carga

---

## 💡 Tips para el Instructor

1. **Preparación Previa**
   - Ejecutar todo el flujo completo antes de la clase
   - Tener un entorno funcionando de respaldo
   - Descargar imágenes Docker previamente si la red es lenta

2. **Durante la Clase**
   - Dedicar tiempo al troubleshooting (es parte del aprendizaje)
   - Fomentar que los alumnos lean los logs
   - Hacer pausas para preguntas

3. **Diferenciación**
   - Alumnos avanzados: proponer modificaciones al código Terraform
   - Alumnos con dificultades: usar el script de setup automático

4. **Tiempo**
   - El setup inicial puede tomar más tiempo de lo esperado
   - Tener el script de setup automático como plan B
   - Considerar hacer el build de imágenes antes de la clase

5. **Engagement**
   - Mostrar ejemplos reales de Kubernetes en producción
   - Comparar con servicios cloud (EKS, GKE, AKS)
   - Discutir casos de uso en la industria

---

## 📚 Recursos Adicionales

### Para el Instructor
- [Kubernetes Patterns](https://k8spatterns.io/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [CNCF Landscape](https://landscape.cncf.io/)

### Para los Alumnos
- [Kubernetes Tutorials](https://kubernetes.io/docs/tutorials/)
- [Kind Documentation](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Terraform Getting Started](https://learn.hashicorp.com/terraform)

---

## 🎓 Próxima Clase

**Tema Sugerido:** CI/CD con GitHub Actions

**Conexión:**
- En esta clase creamos la infraestructura manualmente
- En la próxima automatizaremos el despliegue con CI/CD
- Implementaremos tests automáticos y despliegue continuo

---

## ✅ Checklist del Instructor

Antes de la clase:
- [ ] Ejecutar `./scripts/setup.sh` y verificar que todo funciona
- [ ] Preparar slides de introducción
- [ ] Tener instaladores de herramientas en USB (backup)
- [ ] Revisar la sección de troubleshooting

Durante la clase:
- [ ] Compartir la carpeta clase-4 con los alumnos
- [ ] Asegurar que todos ejecuten `check-prerequisites.sh`
- [ ] Monitorear el progreso de cada alumno
- [ ] Resolver dudas en tiempo real

Después de la clase:
- [ ] Recopilar feedback de los alumnos
- [ ] Documentar problemas comunes que surgieron
- [ ] Actualizar el material si es necesario

---

¡Éxito en tu clase! 🚀

