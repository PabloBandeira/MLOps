# 🍫 INSTALACIÓN DE CHOCOLATEY (Windows)

## 📋 ¿Qué es Chocolatey?

**Chocolatey** es un gestor de paquetes para Windows, similar a Homebrew en macOS o apt/yum en Linux.

### **¿Por qué usarlo?**

✅ Instala herramientas con un solo comando  
✅ Gestiona actualizaciones automáticamente  
✅ Ahorra tiempo vs instalación manual  
✅ Muy usado en desarrollo y DevOps  

### **Herramientas que instalaremos con Chocolatey:**
- `kind` - Kubernetes local
- `kubectl` - CLI de Kubernetes
- `terraform` - Infrastructure as Code

---

## ⚙️ INSTALACIÓN PASO A PASO

### **Paso 1: Abrir PowerShell como Administrador**

1. Presiona `Win + X`
2. Selecciona **"Windows PowerShell (Admin)"** o **"Terminal (Admin)"**
3. Si aparece un diálogo de UAC, haz clic en **"Sí"**

**O busca en el menú inicio:**
- Escribe "PowerShell"
- Clic derecho en "Windows PowerShell"
- Selecciona **"Ejecutar como administrador"**

---

### **Paso 2: Ejecutar el Script de Instalación**

Copia y pega este comando completo en PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**🔍 ¿Qué hace cada línea?**

1. `Set-ExecutionPolicy Bypass` - Permite ejecutar scripts temporalmente
2. `SecurityProtocol` - Configura conexión segura HTTPS
3. `iex (...)` - Descarga y ejecuta el instalador de Chocolatey

**Presiona Enter y espera 1-2 minutos.**

---

### **Paso 3: Verificar Instalación**

```powershell
choco --version
```

**Output esperado:**
```
1.4.0
```

Si ves la versión, **¡listo!** Chocolatey está instalado ✅

---

## 🔧 TROUBLESHOOTING

### **Problema 1: Error "Chocolatey ya está instalado"**

Si el script falla porque Chocolatey ya existe pero no funciona:

#### **A. Verificar si existe:**

```powershell
Get-ChildItem C:\ProgramData\ | Where-Object { $_.Name -match "choco" }
```

**Si ves una carpeta `chocolatey`**, entonces ya está instalado pero posiblemente corrupto.

---

#### **B. Eliminar instalación corrupta:**

```powershell
Remove-Item -Recurse -Force "C:\ProgramData\chocolatey"
```

**⚠️ IMPORTANTE:** Este comando borra la carpeta de Chocolatey. Usa con cuidado.

---

#### **C. Reinstalar desde cero:**

Vuelve a ejecutar el comando de instalación:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

---

### **Problema 2: "No se reconoce 'choco' como comando"**

**Causa:** El PATH no se actualizó en la sesión actual de PowerShell.

**Solución 1 - Refrescar el PATH:**
```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

**Solución 2 - Cerrar y reabrir PowerShell:**
1. Cierra la ventana de PowerShell
2. Abre PowerShell como Administrador nuevamente
3. Intenta `choco --version` de nuevo

---

### **Problema 3: "Execution of scripts is disabled on this system"**

**Causa:** La política de ejecución de PowerShell está muy restrictiva.

**Solución:**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Luego vuelve a ejecutar el script de instalación.

---

### **Problema 4: Chocolatey intenta instalar Docker al instalar Kind**

**Causa:** Kind declara Docker como dependencia, y Chocolatey intenta instalar `docker-desktop`.

**Síntoma:**
```
Installing the following packages:
kind
By installing, you accept licenses for the packages.
Progress: Downloading docker-desktop...
```

**Solución - Usar `--ignore-dependencies`:**
```powershell
choco install kind -y --ignore-dependencies
```

**✅ Esto es SEGURO porque:**
- Ya tienes Docker Desktop instalado de clases anteriores
- Kind solo necesita que Docker esté corriendo, no importa cómo se instaló
- `--ignore-dependencies` evita la reinstalación innecesaria

**Verificar que Docker funciona:**
```powershell
docker --version
docker ps
# Si ambos comandos funcionan, Docker está listo para Kind
```

---

### **Problema 5: Error de red o timeout**

**Causa:** Firewall, antivirus o proxy bloqueando la descarga.

**Soluciones:**

1. **Desactivar temporalmente el antivirus**
2. **Verificar conexión a Internet:**
   ```powershell
   Test-Connection community.chocolatey.org
   ```
3. **Si estás detrás de un proxy corporativo**, configura el proxy:
   ```powershell
   [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
   ```

---

## ✅ VERIFICACIÓN COMPLETA

Después de instalar, verifica que todo funcione:

```powershell
# Ver versión
choco --version

# Ver información del sistema
choco info chocolatey

# Listar paquetes instalados
choco list --local-only
```

**Output esperado:**
```
Chocolatey v1.4.0
Chocolatey (chocolatey 1.4.0)
chocolatey 1.4.0
1 packages installed.
```

---

## 📦 USO BÁSICO DE CHOCOLATEY

### **Instalar un paquete:**
```powershell
choco install nombre-paquete -y
# El flag -y confirma automáticamente
```

### **Buscar paquetes:**
```powershell
choco search nombre-paquete
```

### **Actualizar un paquete:**
```powershell
choco upgrade nombre-paquete -y
```

### **Actualizar todos los paquetes:**
```powershell
choco upgrade all -y
```

### **Listar paquetes instalados:**
```powershell
choco list --local-only
```

### **Desinstalar un paquete:**
```powershell
choco uninstall nombre-paquete -y
```

---

## 🚀 SIGUIENTE PASO

Una vez que Chocolatey esté instalado, puedes instalar las herramientas necesarias para la clase:

### **⚠️ IMPORTANTE: Ya tienes Docker Desktop instalado**

Kind tiene Docker como dependencia, pero **ya lo tienes instalado de clases anteriores**.

**Usa `--ignore-dependencies` para evitar reinstalar Docker:**

```powershell
# Instalar Kind (SIN reinstalar Docker)
choco install kind -y --ignore-dependencies

# Instalar kubectl
choco install kubernetes-cli -y

# Instalar Terraform
choco install terraform -y
```

**💡 ¿Por qué `--ignore-dependencies` en Kind?**
- Kind requiere Docker, pero Chocolatey intentaría instalar `docker-desktop` de nuevo
- `--ignore-dependencies` le dice a Chocolatey: "confía en que Docker ya está instalado"
- Es seguro porque Docker Desktop ya funciona en tu sistema

**⏱️ Tiempo total:** ~5 minutos para instalar las 3 herramientas.

---

## 💡 COMANDOS ÚTILES PARA LA CLASE

### **Ver info de Kind:**
```powershell
choco info kind
```

### **Ver info de kubectl:**
```powershell
choco info kubernetes-cli
```

### **Ver info de Terraform:**
```powershell
choco info terraform
```

### **Actualizar todas las herramientas:**
```powershell
# Kind: usar --ignore-dependencies para no reinstalar Docker
choco upgrade kind -y --ignore-dependencies

# Kubectl y Terraform: actualizaciones normales
choco upgrade kubernetes-cli terraform -y
```

### **Verificar versiones instaladas:**
```powershell
kind --version
kubectl version --client
terraform --version
docker --version  # Verificar que Docker sigue funcionando
```

---

## 📚 RECURSOS ADICIONALES

- **Sitio oficial:** https://chocolatey.org/
- **Documentación:** https://docs.chocolatey.org/en-us/
- **Paquetes disponibles:** https://community.chocolatey.org/packages

---

## 🆘 ¿NECESITAS AYUDA?

Si tienes problemas:

1. ✅ Verifica que PowerShell esté corriendo como **Administrador**
2. ✅ Verifica conexión a Internet
3. ✅ Desactiva temporalmente el antivirus
4. ✅ Si persiste, instala manualmente las herramientas (ver ONBOARDING.md)

---

## 🎯 RESUMEN RÁPIDO

```powershell
# 1. Abrir PowerShell como Administrador

# 2. Instalar Chocolatey:
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 3. Verificar:
choco --version

# 4. Instalar herramientas para la clase:
# IMPORTANTE: Usa --ignore-dependencies para Kind (ya tienes Docker)
choco install kind -y --ignore-dependencies
choco install kubernetes-cli -y
choco install terraform -y

# 5. Verificar instalaciones:
kind --version
kubectl version --client
terraform --version
```

**¡Listo para la Clase 4!** 🚀

---

## ⚠️ NOTAS IMPORTANTES

### **Permisos de Administrador**
- Chocolatey requiere permisos de administrador para instalar paquetes
- Algunos paquetes instalan en `C:\ProgramData\chocolatey\`
- Los binarios se agregan automáticamente al PATH del sistema

### **Actualizaciones**
- Chocolatey puede actualizarse a sí mismo: `choco upgrade chocolatey -y`
- Recomendado: Actualizar antes de instalar nuevos paquetes

### **Desinstalación (si quieres remover Chocolatey)**
```powershell
# 1. Desinstalar todos los paquetes
choco uninstall all -y

# 2. Eliminar Chocolatey
Remove-Item -Recurse -Force "C:\ProgramData\chocolatey"

# 3. Limpiar variables de entorno (opcional)
# Editar manualmente: Win + Pause → Advanced → Environment Variables
```

---

¡Éxito con la instalación! 🍫

