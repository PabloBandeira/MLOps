# Clase 1 - CI/CD + Git/GitHub + Docker

Práctica de MLOps con modelo básico de Machine Learning, integración continua y Docker.

---

## Requisitos

- **Python 3.11**
- **Docker Desktop** (Windows/Mac)
- **Git Bash** (Windows) o Terminal (Mac)
- Cuenta **GitHub**

---

## Árbol del Proyecto

```
clase-1/
├─ src/
│  └─ train.py
├─ tests/
│  └─ test_train.py
├─ .github/workflows/
│  └─ ci.yml
├─ Dockerfile
├─ requirements.txt
├─ requirements-dev.txt
├─ .pre-commit-config.yaml
├─ .gitattributes
├─ .gitignore
├─ README.md
└─ ONBOARDING.md
```

---

## Instalación y Setup

### Windows (Git Bash)

```bash
# Crear virtual environment
py -3.11 -m venv .venv || python -m venv .venv

# Activar venv
source .venv/Scripts/activate

# Instalar dependencias
python -m pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Instalar pre-commit hooks
pre-commit install
```

### Mac (bash/zsh)

```bash
# Crear virtual environment
python3.11 -m venv .venv

# Activar venv
source .venv/bin/activate

# Instalar dependencias
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Instalar pre-commit hooks
pre-commit install
```

---

## Ejecución

### Entrenar modelo

**Windows (Git Bash)**

```bash
python src/train.py
```

**Mac (bash/zsh)**

```bash
python src/train.py
```

**Salida esperada:**

```
acc: 0.9667
f1_macro: 0.9667
```

---

### Ejecutar tests

**Windows (Git Bash)**

```bash
pytest -v
```

**Mac (bash/zsh)**

```bash
pytest -v
```

**Salida esperada:**

```
tests/test_train.py::test_train_returns_valid_metrics PASSED
tests/test_train.py::test_train_reproducibility PASSED
===================== 2 passed in 0.XX s =====================
```

---

### Pre-commit checks

**Windows (Git Bash)**

```bash
pre-commit run --all-files
```

**Mac (bash/zsh)**

```bash
pre-commit run --all-files
```

**Salida esperada:**

```
black....................................................................Passed
ruff.....................................................................Passed
```

---

## Docker

### Build imagen

**Windows (Git Bash)**

```bash
docker build -t demo-ml:local .
```

**Mac (bash/zsh)**

```bash
docker build -t demo-ml:local .

# Si Apple Silicon y hay problemas:
docker build --platform=linux/amd64 -t demo-ml:local .
```

---

### Run contenedor

**Windows (Git Bash)**

```bash
# Con montaje de volumen
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local

# Modo interactivo (bash)
winpty docker run -it --rm -v "$PWD:/app" demo-ml:local bash
```

**Mac (bash/zsh)**

```bash
# Con montaje de volumen
docker run --rm -v "$PWD:/app" demo-ml:local

# Modo interactivo (bash)
docker run -it --rm -v "$PWD:/app" demo-ml:local bash

# Si Apple Silicon y hay problemas:
docker run --rm --platform=linux/amd64 -v "$PWD:/app" demo-ml:local
```

**Salida esperada:**

```
acc: 0.9667
f1_macro: 0.9667
```

---

## GitHub Actions (CI/CD)

El workflow `.github/workflows/ci.yml` se ejecuta automáticamente en cada push/PR:

1. Instala Python 3.11
2. Instala dependencias
3. Ejecuta `pre-commit` checks
4. Ejecuta `pytest`
5. Construye imagen Docker

**Para activar CI:**

```bash
# Inicializar repo (si no existe)
git init
git add .
git commit -m "Initial commit - Clase 1"

# Crear repo en GitHub y pushear
git remote add origin https://github.com/<usuario>/<repo>.git
git push -u origin main
```

---

## Troubleshooting

### Windows Git Bash

**Error: `py: command not found`**

```bash
# Usar python directamente
python -m venv .venv
```

**Error: Docker paths con `C:\...`**

```bash
# Usar MSYS_NO_PATHCONV=1
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local
```

**Error: Docker interactivo no funciona**

```bash
# Usar winpty
winpty docker run -it --rm demo-ml:local bash
```

**Error: Scripts `.sh` con CRLF**

```bash
# Convertir a LF
dos2unix scripts/*.sh

# O configurar Git
git config --global core.autocrlf input
```

---

### Mac

**Error: `python3.11: command not found`**

```bash
# Instalar Python 3.11 con Homebrew
brew install python@3.11

# Verificar instalación
python3.11 --version
```

**Error: Docker (Apple Silicon) incompatibilidad**

```bash
# Usar platform linux/amd64
docker build --platform=linux/amd64 -t demo-ml:local .
docker run --rm --platform=linux/amd64 demo-ml:local
```

---

## Smoke Test Completo

### Windows (Git Bash)

```bash
py -3.11 -m venv .venv || python -m venv .venv
source .venv/Scripts/activate
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt
pre-commit install
pre-commit run --all-files
pytest -q
python src/train.py
docker build -t demo-ml:local .
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local
```

### Mac (bash/zsh)

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt
pre-commit install
pre-commit run --all-files
pytest -q
python src/train.py
docker build -t demo-ml:local .
docker run --rm -v "$PWD:/app" demo-ml:local
```

---

## Salidas Esperadas Resumidas

| Comando | Salida Esperada |
|---------|----------------|
| `pytest -q` | `2 passed` |
| `python src/train.py` | `acc: 0.9667` |
| `docker run ...` | `acc: 0.9667` |
| `pre-commit run --all-files` | `Passed` (black, ruff) |
| GitHub Actions | ✓ Badge verde |

---

## Próximos Pasos

Ver **ONBOARDING.md** para:
- Activar GitHub Copilot (Student Pack)
- Configuración inicial del entorno
- Chequeos de validación

