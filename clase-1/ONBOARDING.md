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
py -3.11 -m venv .venv || python -m venv .venv
source .venv/Scripts/activate

# Verificar activación (debe mostrar ruta a .venv)
which python

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Configurar pre-commit
pre-commit install

# Verificar instalación
pytest -q
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
python3.11 -m venv .venv
source .venv/bin/activate

# Verificar activación (debe mostrar ruta a .venv)
which python

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Configurar pre-commit
pre-commit install

# Verificar instalación
pytest -q
python src/train.py
```

**Si Apple Silicon (M1/M2/M3):**

```bash
# Usar platform específica si hay problemas
docker build --platform=linux/amd64 -t demo-ml:local .
docker run --rm --platform=linux/amd64 -v "$PWD:/app" demo-ml:local
```

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
pytest -q
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
acc: 0.9667
f1_macro: 0.9667
```

---

### 4. Docker build

**Windows (Git Bash):**

```bash
docker build -t demo-ml:local .
```

**Mac:**

```bash
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
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local
```

**Mac:**

```bash
docker run --rm -v "$PWD:/app" demo-ml:local
```

**Salida esperada:**

```
acc: 0.9667
f1_macro: 0.9667
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

## Crear Repositorio GitHub

**Desde la línea de comandos:**

```bash
# Inicializar repo
git init

# Agregar archivos
git add .

# Commit inicial
git commit -m "Initial commit - Clase 1"

# Crear repo en GitHub (manual) y conectar:
git remote add origin https://github.com/<usuario>/<repo>.git
git branch -M main
git push -u origin main
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

Una vez que todos los chequeos pasen, estás listo para:

1. Pushear tu código a GitHub
2. Verificar que el CI/CD (GitHub Actions) pase
3. Continuar con **Clase 2 - MLflow**

