# Onboarding - Clase 1

Guía rápida para configurar el entorno de MLOps.

---

## Activar GitHub Copilot (Alumnos Austral)

1. Ir a: `https://github.com/settings/education/benefits`

2. Solicitar acceso a **GitHub Education / Student Developer Pack**

3. **Adjuntar certificado de alumno regular de la Universidad Austral**

4. Una vez aprobado (puede tardar 1-3 días), activar **GitHub Copilot** en tu cuenta

5. Instalar extensión de **GitHub Copilot** en tu IDE (VS Code, PyCharm, etc.)

---

## Instalar Visual Studio Code

**Descargar e instalar VS Code:**

1. Ir a: `https://code.visualstudio.com/`
2. Descargar la versión para tu OS (Windows, Mac, Linux)
3. Instalar siguiendo los pasos del instalador
4. Abrir VS Code

---

## Clonar el Repositorio

Una vez tengas VS Code instalado, clonaremos el repositorio desde GitHub:

### Opción 1: Desde VS Code (Recomendado)

1. Abrir **VS Code**
2. Presionar `Ctrl+Shift+P` (Windows/Linux) o `Cmd+Shift+P` (Mac)
3. Buscar y seleccionar **"Git: Clone"**
4. Pegar la URL del repositorio:
   ```
   https://github.com/PabloBandeira/MLOps.git
   ```
5. Seleccionar dónde guardar (ej: `~/Desktop/MLops`)
6. VS Code abrirá automáticamente el repositorio

### Opción 2: Desde Terminal

```bash
# Navegar a donde quieras guardar el proyecto
cd ~/Desktop

mkdir MLops

cd MLops

# Clonar el repositorio
git clone https://github.com/PabloBandeira/MLOps.git

# Entrar al directorio
cd MLops/clase-1
```

---

## Workflow: Subir tus Cambios (Alumnos)

Una vez hayas clonado el repositorio, seguirás este workflow para subir tus modificaciones y resultados:

### 1. Crear tu rama personal

```bash
# Crear y cambiar a tu rama (usa tu nombre o identificador)
git checkout -b feature/tu-nombre
```

**Ejemplo:**
```bash
git checkout -b feature/juan-perez
```

---

### 2. Hacer cambios y experimentar

Ahora puedes modificar archivos, agregar experimentos, scripts, etc. Tu rama es segura y no afectará el código principal.

```bash
# Edita archivos, agrega experimentos, modifica resultados...
```

---

### 3. Subir tus cambios

```bash
# Ver qué cambios hiciste
git status

# Agregar tus cambios
git add .

# Crear commits con descripciones claras (puedes hacer varios)
git commit -m "Experimento: [descripción de qué hiciste]"

# Ejemplos:
git commit -m "Experimento: Ajusté hiperparámetros del modelo"
git commit -m "Agregué visualizaciones de resultados"
git commit -m "Mejoré accuracy a 0.95"

# Primer push a la rama

git push --set-upstream origin feature/tu-nombre

# Pushear tu rama al repositorio
git push origin feature/tu-nombre
```

---

### 4. El profesor revisa tu código

El profesor accede a GitHub y revisa:
- Tu rama en: `https://github.com/PabloBandeira/MLOps`
- Todos tus commits
- Los cambios que hiciste
- Tus resultados y experimentos

**Tu código está visible para revisar.**

---

### ⚠️ Importante

- **NO pushees directamente a `main`** - siempre usa tu rama personal (`feature/tu-nombre`)
- Cada cambio importante = nuevo commit con descripción clara
- Los commits permiten que el profesor vea el progreso paso a paso
- Tu rama se mantiene segura y separada del código principal

---

## Setup Rápido por OS

### Windows (Git Bash)

**Requisitos previos:**

- Instalar **Docker Desktop**: https://www.docker.com/products/docker-desktop
- Instalar **Python 3.11**: https://www.python.org/downloads/
- Instalar **Git for Windows** (incluye Git Bash): https://git-scm.com/download/win

**Setup del proyecto:**

```bash
# Navegar a la carpeta del proyecto
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-1

# Crear y activar venv
py -3.11 -m venv .venv || python -m venv .venv || python3 -m venv .venv
source .venv/Scripts/activate

# Verificar activación (debe mostrar ruta a .venv)
which python

# Entramos a la carpeta de la clase 1 para instalar las librerias
cd clase-1

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Configurar pre-commit
pre-commit install

# Verificar instalación
python -m pytest -q
python src/train.py
```

---

### Mac (bash/zsh)

**Requisitos previos:**

- Instalar **Docker Desktop**: https://www.docker.com/products/docker-desktop
- Instalar **Python 3.11**:

```bash
# Con Homebrew
brew install python@3.11

# Verificar
python3.11 --version
```

**Setup del proyecto:**

```bash
# Navegar a la carpeta del proyecto
cd ~/Desktop/MLops/clase-1

# Crear y activar venv
python3.11 -m venv .venv || python -m venv .venv || python3 -m venv .venv
source .venv/bin/activate

# Verificar activación (debe mostrar ruta a .venv)
which python

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt


# Analizamos el codigo de src/train.py

---

## Chequeos de Validación

Ejecutar cada comando y verificar la salida esperada:

### 1. Pre-commit checks

**Comando:**

```bash
pre-commit run --all-files
```

**Salida esperada:**

```
black....................................................................Passed
ruff.....................................................................Passed
```

---

### 2. Tests

**Comando:**

```bash
python -m pytest -q
```

**Salida esperada:**

```
..                                                                [100%]
2 passed in 0.XX s
```

---

### 3. Entrenamiento local

**Comando:**

```bash
python src/train.py
```

**Salida esperada:**

```
acc: 0.9667 | acc: 1.0000
f1_macro: 0.9667 | f1_macro: 1.0000
```

---

### 4. Docker build

**ABRIR DOCKER DESKTOP**

**Windows (Git Bash):**

```bash
# Navegar a la carpeta del proyecto primero
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-1

# Construir imagen
docker build -t demo-ml:local .
```

**Mac:**

```bash
# Navegar a la carpeta del proyecto primero
cd ~/Desktop/MLops/clase-1

# Construir imagen
docker build -t demo-ml:local .
```

**Salida esperada:**

```
[+] Building X.Xs (X/X) FINISHED
 => [internal] load build definition from Dockerfile
 ...
 => => naming to docker.io/library/demo-ml:local
```

---

### 5. Docker run

**Windows (Git Bash):**

```bash
# Asegúrate de estar en la carpeta clase-1
cd /c/Users/<tu-usuario>/Desktop/MLops/clase-1

# Ejecutar contenedor
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local

# Si estás en Powershell
$Env:MSYS_NO_PATHCONV=1; docker run --rm -v "${PWD}:/app" demo-ml:local
```

**Salida esperada:**

acc: 0.9667 | acc: 1.0000
f1_macro: 0.9667 | f1_macro: 1.0000
```
```
**Mac:**

```bash
# Asegúrate de estar en la carpeta clase-1
cd ~/Desktop/MLops/clase-1

# Ejecutar contenedor
docker run --rm -v "$PWD:/app" demo-ml:local
```

**Salida esperada:**

acc: 0.9667 | acc: 1.0000
f1_macro: 0.9667 | f1_macro: 1.0000
```
```
**Apple Silicon (M1/M2/M3) - Si Docker falla:**

Si tienes problemas con Docker en Mac Apple Silicon, usa estos comandos en lugar de los normales:

```bash
# En lugar de: docker build -t demo-ml:local .
docker build --platform=linux/amd64 -t demo-ml:local .

# En lugar de: docker run --rm -v "$PWD:/app" demo-ml:local
docker run --rm --platform=linux/amd64 -v "$PWD:/app" demo-ml:local
```


**Salida esperada:**

```
acc: 0.9667 | acc: 1.0000
f1_macro: 0.9667 | f1_macro: 1.0000
```

---

## Configuración Git

**Configurar identidad (si no lo hiciste antes):**

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu.email@ejemplo.com"
```

**Configurar line endings (importante para Windows):**

```bash
git config --global core.autocrlf input
```


---

## Problemas Comunes

### Windows Git Bash

**`py` no funciona:**

```bash
# Alternativa: usar python directamente
python --version
python -m venv .venv
```

**Docker paths no funcionan:**

```bash
# Siempre usar MSYS_NO_PATHCONV=1 con -v
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local
```

**Scripts `.sh` no ejecutan:**

```bash
# Convertir a LF si hace falta
dos2unix scripts/*.sh

# O ejecutar con bash explícitamente
bash scripts/nombre.sh
```

---

### Mac

**`python3.11` no encontrado:**

```bash
# Instalar con Homebrew
brew install python@3.11

# Crear symlink si hace falta
brew link python@3.11
```

**Permission denied en Docker:**

```bash
# Agregar usuario a grupo docker
sudo usermod -aG docker $USER

# Logout y login nuevamente
```


---

## Resumen de Comandos por OS

| Tarea | Windows (Git Bash) | Mac (bash/zsh) |
|-------|-------------------|----------------|
| Crear venv | `py -3.11 -m venv .venv` | `python3.11 -m venv .venv` |
| Activar venv | `source .venv/Scripts/activate` | `source .venv/bin/activate` |
| Docker run | `MSYS_NO_PATHCONV=1 docker run -v "$PWD:/app"` | `docker run -v "$PWD:/app"` |
| Docker interactivo | `winpty docker run -it` | `docker run -it` |

---

## Siguiente Paso

Una vez que todos los chequeos pasen localmente (en tu máquina):

1. **Crear tu rama**: `git checkout -b feature/tu-nombre`
2. **Hacer cambios** 
PROBLEMATICA add . y venv con librerías. Como arreglarlo?

Utilizamos Github copilot. 
Necesitamos que genere un .gitignore para no incluir las librerías de venv.


3. **Pushear** a tu rama
4. **GitHub Actions correrá automáticamente** en tu rama y verás si los tests pasan
5. **El profesor revisará tu rama** directamente en GitHub
6. Cuando estés listo, continúa con **Clase 2 - MLflow**


