================================================================================
                        📑 ÍNDICE - CLASE 5: AWS EKS
================================================================================

🎯 INICIO RÁPIDO
────────────────────────────────────────────────────────────────────────────

Para usuarios apurados:
1. Lee COMIENZA_AQUI.txt (5 min)
2. Ejecuta ./scripts/check-prerequisites-aws.sh (1 min)
3. Edita infra/terraform.tfvars (2 min)
4. Ejecuta ./scripts/setup-eks.sh (20 min - espera pasivamente)
5. Ejecuta ./scripts/push-to-ecr.sh (5 min)
6. Edita infra/terraform.tfvars (ecr_url) (1 min)
7. Ejecuta cd infra && terraform apply (10 min)
8. Ejecuta kubectl get svc (1 min - obtén URLs)
9. IMPORTANTE: ./scripts/destroy-eks.sh (5 min - cuando termines)

Total: ~50 minutos


📚 DOCUMENTOS POR ORDEN DE LECTURA
────────────────────────────────────────────────────────────────────────────

1️⃣  COMIENZA_AQUI.txt
    Archivo: /Users/pablo/Desktop/MLops/clase-5/COMIENZA_AQUI.txt
    Tiempo: 5 min
    Qué es:
    - Introducción general a la clase 5
    - Objetivos de aprendizaje
    - Estructura del proyecto
    - Flujo de trabajo resumido
    - Costos estimados
    
    Después de leer: Vas a GUIA_MIGRACION_COMPLETA.md


2️⃣  RESUMEN_VISUAL.txt
    Archivo: /Users/pablo/Desktop/MLops/clase-5/RESUMEN_VISUAL.txt
    Tiempo: 10 min
    Qué es:
    - Diagramas de arquitectura
    - Comparación visual KIND vs EKS
    - Flujo de trabajo paso a paso
    - Checklist de preparación
    - Advertencias importantes
    
    Después de leer: Vas a GUIA_MIGRACION_COMPLETA.md


3️⃣  GUIA_MIGRACION_COMPLETA.md ⭐ LA MÁS IMPORTANTE
    Archivo: /Users/pablo/Desktop/MLops/clase-5/GUIA_MIGRACION_COMPLETA.md
    Tiempo: 60-90 min (mientras ejecutas comandos)
    Qué es:
    - Guía paso a paso completa
    - Todos los comandos necesarios
    - Explicaciones detalladas
    - Validación en cada paso
    - Script de limpieza final
    
    Secciones:
    ├─ Preparación Inicial (10 min)
    ├─ Configuración de AWS (10 min)
    ├─ Provisionamiento de EKS (30 min)
    ├─ Migración de Imágenes (10 min)
    ├─ Despliegue de Servicios (10 min)
    ├─ Validación y Pruebas (10 min)
    ├─ Monitoreo y Costos (5 min)
    ├─ Limpieza y Destrucción (5 min)
    └─ Checklist final
    
    Después de ejecutar: Vas a COMPARACION_KIND_VS_EKS.md (para aprender)


4️⃣  COMPARACION_KIND_VS_EKS.md
    Archivo: /Users/pablo/Desktop/MLops/clase-5/COMPARACION_KIND_VS_EKS.md
    Tiempo: 20 min
    Qué es:
    - Diferencias técnicas exhaustivas
    - Tabla comparativa
    - Casos de uso para cada uno
    - Análisis de costos
    - Escalabilidad
    
    Cuándo leerlo:
    - Después de que el cluster esté funcionando
    - Para entender qué hace diferente a EKS
    - Para decidir cuándo usar uno u otro
    
    Después de leer: Vas a ARQUITECTURA_AWS.md


5️⃣  ARQUITECTURA_AWS.md
    Archivo: /Users/pablo/Desktop/MLops/clase-5/ARQUITECTURA_AWS.md
    Tiempo: 20 min
    Qué es:
    - Diagrama completo de la arquitectura
    - Explicación de VPC, subnets, security groups
    - Componentes Kubernetes desplegados
    - Almacenamiento con EBS
    - IAM roles y permisos
    - High availability
    - Auto-scaling
    
    Cuándo leerlo:
    - Cuando quieras entender la infraestructura en detalle
    - Después de kubectl get pods
    - Para debugging avanzado
    
    Después de leer: Vas a TROUBLESHOOTING_AWS.md (si hay problemas)


6️⃣  TROUBLESHOOTING_AWS.md
    Archivo: /Users/pablo/Desktop/MLops/clase-5/TROUBLESHOOTING_AWS.md
    Tiempo: 10 min (búsqueda rápida) o 30 min (lectura completa)
    Qué es:
    - Errores comunes y soluciones
    - Debugging avanzado
    - Checklist de diagnóstico
    - Problemas de costos
    - Recursos de soporte
    
    Secciones:
    ├─ Errores comunes (12 errores con solución)
    ├─ Errores de costos
    ├─ Debugging avanzado
    └─ Checklist de diagnóstico
    
    Cuándo leerlo:
    - Cuando algo no funcione
    - kubectl logs no ayuda
    - Tienes ImagePullBackOff
    - LoadBalancer stuck in pending
    
    Después de leer: Contacta al instructor si persiste


7️⃣  README.md
    Archivo: /Users/pablo/Desktop/MLops/clase-5/README.md
    Tiempo: 15 min
    Qué es:
    - Documentación general del proyecto
    - Estructura de carpetas
    - Requisitos previos
    - Comandos útiles
    - Conceptos clave
    - Checklist de finalización
    
    Cuándo leerlo:
    - Como referencia general
    - Antes de empezar (para visión general)
    - Para comandos útiles
    
    Después de leer: ¡Empezar a trabajar!


================================================================================
                        📁 ESTRUCTURA DE CARPETAS
================================================================================

clase-5/
│
├─ 📄 Documentación
│  ├─ COMIENZA_AQUI.txt              ← EMPIEZA AQUÍ (Lee primero)
│  ├─ RESUMEN_VISUAL.txt             ← Diagramas y resumen (Lee segundo)
│  ├─ GUIA_MIGRACION_COMPLETA.md     ← Guía detallada (SIGUE ESTO)
│  ├─ COMPARACION_KIND_VS_EKS.md     ← Análisis técnico
│  ├─ ARQUITECTURA_AWS.md            ← Diagramas de infra
│  ├─ TROUBLESHOOTING_AWS.md         ← Solución de problemas
│  ├─ README.md                      ← Documentación general
│  └─ INDEX.md                       ← Este archivo
│
├─ 📁 infra/                          ← Terraform (Infrastructure as Code)
│  ├─ provider.tf                    ← Configuración de providers AWS/Kubernetes
│  ├─ variables.tf                   ← Variables de entrada (tipos y defaults)
│  ├─ terraform.tfvars               ← TUS VALORES (EDITA ESTO)
│  ├─ outputs.tf                     ← Información de salida
│  │
│  ├─ networking.tf                  ← VPC, subnets, security groups
│  ├─ iam-roles.tf                   ← Roles IAM y políticas
│  ├─ eks.tf                         ← Clúster EKS, nodos y addons
│  ├─ ecr.tf                         ← Repositorios de imágenes Docker
│  ├─ storage.tf                     ← EBS volumes y storage classes
│  │
│  ├─ mlflow.tf                      ← Deployment de MLflow
│  ├─ evidently.tf                   ← Deployment de Evidently
│  ├─ iris-api.tf                    ← Deployment de Iris API
│  └─ workspace.tf                   ← Deployment de Jupyter Lab
│
├─ 📁 app_iris/                       ← API de predicción (igual a clase-4)
│  ├─ Dockerfile                     ← Se sube a ECR
│  ├─ main.py                        ← FastAPI con modelo
│  ├─ train.py                       ← Entrenamiento en build-time
│  └─ requirements.txt               ← Dependencias Python
│
├─ 📁 app_workspace/                  ← Jupyter Lab (igual a clase-4)
│  ├─ Dockerfile                     ← Se sube a ECR
│  ├─ requirements.txt               ← Dependencias Python
│  └─ (otros archivos)
│
├─ 📁 scripts/                        ← Scripts de automatización
│  ├─ check-prerequisites-aws.sh     ← Verifica herramientas instaladas
│  ├─ setup-eks.sh                   ← Provisiona cluster EKS
│  ├─ push-to-ecr.sh                 ← Construye y sube imágenes a ECR
│  └─ destroy-eks.sh                 ← Destruye TODO (¡CUIDADO!)
│
└─ 📁 notebooks/                      ← Material de práctica (de clase-4)
   └─ 01_simulacion.ipynb            ← Notebook con simulación


================================================================================
                        🔍 BUSQUEDA RÁPIDA POR TEMA
================================================================================

Si quiero saber...                    Leer archivo...
────────────────────────────────────────────────────────────────────────────
Qué voy a aprender en esta clase    → COMIENZA_AQUI.txt
Cuál es el plan exacto               → GUIA_MIGRACION_COMPLETA.md
Diferencia con KIND                  → COMPARACION_KIND_VS_EKS.md
Cómo se vé la arquitectura           → ARQUITECTURA_AWS.md
Qué comandos usar                    → README.md (sección "Comandos útiles")
Me está fallando algo                → TROUBLESHOOTING_AWS.md
Cuánto va a costar                   → COMPARACION_KIND_VS_EKS.md (sección Costos)
Dónde están los archivos Terraform   → INDEX.md (sección Estructura)
Cómo configuro AWS CLI               → GUIA_MIGRACION_COMPLETA.md (Paso 3)
Cómo sé que todo está listo          → README.md (sección Checklist)


================================================================================
                        ⏱️ CRONOGRAMA RECOMENDADO
================================================================================

DÍA 1: PREPARACIÓN Y LECTURA
─────────────────────────────

09:00 - Lee COMIENZA_AQUI.txt                          (5 min)
09:05 - Lee RESUMEN_VISUAL.txt                         (10 min)
09:15 - Instala herramientas si falta                  (15 min)
09:30 - Ejecuta ./scripts/check-prerequisites-aws.sh   (5 min)
09:35 - Lee GUIA_MIGRACION_COMPLETA.md Parte 1        (15 min)
09:50 - Edita infra/terraform.tfvars                   (5 min)
09:55 - DESCANSO (10 min)
10:05 - Lee GUIA_MIGRACION_COMPLETA.md Parte 2        (15 min)

DÍA 2: PROVISIÓN Y DESPLIEGUE
──────────────────────────────

09:00 - Ejecuta ./scripts/setup-eks.sh                 (25 min - espera pasivamente)
09:25 - Mientras esperas: Lee GUIA_MIGRACION_COMPLETA.md Parte 3
09:45 - Cluster creado: Verifica con kubectl get nodes (5 min)
09:50 - Ejecuta ./scripts/push-to-ecr.sh               (15 min)
10:05 - Edita infra/terraform.tfvars (ecr_url)         (2 min)
10:07 - Ejecuta cd infra && terraform apply            (15 min)
10:22 - Obtén URLs: kubectl get svc                    (2 min)
10:24 - Testea servicios (MLflow, Jupyter, API)        (10 min)
10:34 - Lee COMPARACION_KIND_VS_EKS.md                 (20 min)
10:54 - DESCANSO (10 min)
11:04 - Lee ARQUITECTURA_AWS.md                        (20 min)
11:24 - Experimenta con kubectl commands               (15 min)
11:39 - Prepara destrucción: lee Paso 25 de guía       (5 min)
11:44 - Ejecuta ./scripts/destroy-eks.sh               (5 min)
11:49 - Verifica en AWS Console que está limpio        (10 min)

Total: ~4 horas en 2 días


================================================================================
                        ✅ PUNTOS DE CONTROL
================================================================================

Después de cada sección, verifica:

DESPUÉS DE: ./scripts/check-prerequisites-aws.sh
  ✅ Todo verde (✅ marks)
  ✅ AWS CLI funcionando
  ✅ Credenciales válidas

DESPUÉS DE: terraform init
  ✅ Carpeta .terraform/ creada
  ✅ .terraform.lock.hcl generado
  ✅ Sin errores

DESPUÉS DE: terraform apply (infraestructura)
  ✅ Clúster EKS creado (AWS Console)
  ✅ VPC y subnets creadas
  ✅ Nodos EC2 running
  ✅ kubectl get nodes → STATUS: Ready

DESPUÉS DE: ./scripts/push-to-ecr.sh
  ✅ iris-api:latest en ECR
  ✅ workspace:latest en ECR
  ✅ aws ecr describe-images funciona

DESPUÉS DE: terraform apply (servicios)
  ✅ kubectl get pods → STATUS: Running
  ✅ kubectl get svc → EXTERNAL-IP no pending
  ✅ curl http://IP:PUERTO funciona

ANTES DE: ./scripts/destroy-eks.sh
  ✅ Experimentaste con el cluster
  ✅ Ejecutaste el notebook
  ✅ Tomaste notas


================================================================================
                        📞 ¿NECESITAS AYUDA?
================================================================================

¿Qué debo hacer si...?

❌ No tengo AWS Account
   → Crea uno en https://aws.amazon.com/
   → Tienes 12 meses gratis

❌ Las herramientas no se instalan
   → Lee TROUBLESHOOTING_AWS.md (Sección: Instalar herramientas)
   → Pregunta al instructor

❌ Mi cluster tarda más de 20 min en crearse
   → Normal, EKS puede tardar hasta 30 minutos
   → Paciencia, está bien

❌ Un pod está en ImagePullBackOff
   → Lee TROUBLESHOOTING_AWS.md (Sección: ImagePullBackOff)
   → Verifica: aws ecr describe-images

❌ El LoadBalancer está "pending"
   → Es normal los primeros 1-2 minutos
   → Espera y haz: kubectl get svc -w

❌ Mi factura de AWS fue más de lo esperado
   → ¡Ahora lo sabes! Siempre destruye con terraform destroy
   → Lee: COMPARACION_KIND_VS_EKS.md (Cómo reducir costos)
   → No hay cargo si no hay recursos

❌ Tengo un error que no está en TROUBLESHOOTING_AWS.md
   → Lee el mensaje de error completamente
   → Ejecuta: kubectl describe pod <POD_NAME>
   → Mira los logs: kubectl logs <POD_NAME>
   → Pregunta al instructor


================================================================================
                        📊 COMPARATIVA RÁPIDA
================================================================================

            KIND                    EKS
────────────────────────────────────────────────────────
Costo      $0                      ~$160/mes
Setup      5 min                   20 min
Escalabilidad  1-3 nodos           1-1000+ nodos
Ideal para     Desarrollo          Producción
Storage    Efímero                 Persistente
Acceso     localhost:30xxx         DNS público


================================================================================
                        🚀 PRÓXIMOS PASOS
================================================================================

Después de completar esta clase:

Nivel Básico → Productividad:
  1. Personalizar los deployments
  2. Agregar más replicas
  3. Experimentar con scaling

Nivel Intermedio → Robustez:
  1. Agregar HTTPS/TLS
  2. Usar RDS en lugar de SQLite
  3. Implementar backup

Nivel Avanzado → Profesional:
  1. CI/CD con CodePipeline
  2. Monitoreo con Prometheus
  3. Auto-scaling avanzado
  4. Multi-región


================================================================================
                    ¡LISTO PARA EMPEZAR! 🚀
          Lee COMIENZA_AQUI.txt y sigue GUIA_MIGRACION_COMPLETA.md
================================================================================


