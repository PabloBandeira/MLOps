# Clase 2 - MLflow Tracking & Model Serving

Práctica de MLOps con MLflow para tracking de experimentos, registro de modelos y serving.

---

## Diferencias con Clase 1

Esta clase extiende la Clase 1 agregando capacidades de MLflow:

### Archivos NUEVOS:

- `src/train_mlflow.py`: Entrenamiento con tracking de MLflow
- `tests/test_train_mlflow.py`: Tests para el módulo MLflow
- `scripts/run_experiments.sh`: Script para ejecutar múltiples experimentos
- `scripts/serve_model.sh`: Script para servir modelos con MLflow

### Archivos MODIFICADOS:

- `requirements.txt`: Agregado `mlflow==2.9.2`
- `Dockerfile`: Agregado `COPY scripts/` y `EXPOSE 9000`

### Funcionalidades agregadas:

- ✅ Tracking de parámetros, métricas y modelos
- ✅ Registro automático de modelos en MLflow
- ✅ Comparación de experimentos vía UI
- ✅ Model serving con API REST
- ✅ Scripts automatizados para experimentación

---

## Requisitos

- **Python 3.11**
- **Docker Desktop** (Windows/Mac)
- **Git Bash** (Windows) o Terminal (Mac)
- Cuenta **GitHub**

---

## Árbol del Proyecto

```
clase-2/
├─ src/
│  ├─ train.py
│  └─ train_mlflow.py          [NUEVO]
├─ tests/
│  ├─ test_train.py
│  └─ test_train_mlflow.py     [NUEVO]
├─ scripts/                     [NUEVO]
│  ├─ run_experiments.sh
│  └─ serve_model.sh
├─ .github/workflows/
│  └─ ci.yml
├─ Dockerfile                   [MODIFICADO]
├─ requirements.txt             [MODIFICADO]
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

### 1. Entrenar modelo básico (sin MLflow)

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

### 2. Entrenar modelo con MLflow

**Windows (Git Bash)**

```bash
python src/train_mlflow.py
```

**Mac (bash/zsh)**

```bash
python src/train_mlflow.py
```

**Salida esperada:**

```
Run ID: abc123def456789...
acc: 0.9667
f1_macro: 0.9667
precision_macro: 0.9667
recall_macro: 0.9667
```

---

### 3. Ejecutar tests

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
tests/test_train_mlflow.py::test_train_mlflow_returns_valid_metrics PASSED
tests/test_train_mlflow.py::test_train_mlflow_reproducibility PASSED
tests/test_train_mlflow.py::test_train_mlflow_different_params PASSED
===================== 5 passed in 0.XX s =====================
```

---

### 4. Pre-commit checks

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

## MLflow

### Levantar MLflow UI

**Windows (Git Bash)**

```bash
mlflow ui --port 5000
```

**Mac (bash/zsh)**

```bash
mlflow ui --port 5000
```

**Salida esperada:**

```
[INFO] Starting gunicorn 20.1.0
[INFO] Listening at: http://127.0.0.1:5000
```

**Abrir navegador:** `http://127.0.0.1:5000`

---

### Ejecutar múltiples experimentos

**Windows (Git Bash)**

```bash
bash scripts/run_experiments.sh
```

**Mac (bash/zsh)**

```bash
bash scripts/run_experiments.sh
```

**Salida esperada:**

```
==========================================
Ejecutando experimentos de MLflow
==========================================

Experimento 1: n_estimators=50, max_depth=5
Run ID: abc123...
acc: 0.9333
f1_macro: 0.9333
precision_macro: 0.9333
recall_macro: 0.9333

Experimento 2: n_estimators=100, max_depth=10
Run ID: def456...
acc: 0.9667
f1_macro: 0.9667
precision_macro: 0.9667
recall_macro: 0.9667

Experimento 3: n_estimators=150, max_depth=None
Run ID: ghi789...
acc: 0.9667
f1_macro: 0.9667
precision_macro: 0.9667
recall_macro: 0.9667

==========================================
✓ Experimentos completados
Ver resultados en: mlflow ui --port 5000
==========================================
```

---

### Servir modelo

**Opción 1: Script automatizado**

**Windows (Git Bash)**

```bash
bash scripts/serve_model.sh
```

**Mac (bash/zsh)**

```bash
bash scripts/serve_model.sh
```

El script te mostrará el último run ID y te preguntará si deseas servir el modelo.

---

**Opción 2: Manual**

**Terminal 1 - Servir modelo:**

```bash
# Reemplazar <RUN_ID> con el ID real de MLflow UI
mlflow models serve -m runs:/<RUN_ID>/model -p 9000 --no-conda
```

**Terminal 2 - Probar con curl:**

**Windows (Git Bash)**

```bash
curl -X POST http://127.0.0.1:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'
```

**Mac (bash/zsh)**

```bash
curl -X POST http://127.0.0.1:9000/invocations \
  -H 'Content-Type: application/json' \
  -d '{"dataframe_split": {"columns": ["0", "1", "2", "3"], "data": [[5.1, 3.5, 1.4, 0.2]]}}'
```

**Salida esperada:**

```json
{"predictions": [0]}
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

# Ejecutar train_mlflow dentro del contenedor
MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD:/app" demo-ml:local python src/train_mlflow.py
```

**Mac (bash/zsh)**

```bash
# Con montaje de volumen
docker run --rm -v "$PWD:/app" demo-ml:local

# Modo interactivo (bash)
docker run -it --rm -v "$PWD:/app" demo-ml:local bash

# Ejecutar train_mlflow dentro del contenedor
docker run --rm -v "$PWD:/app" demo-ml:local python src/train_mlflow.py

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
2. Instala dependencias (incluyendo MLflow)
3. Ejecuta `pre-commit` checks
4. Ejecuta `pytest`
5. Construye imagen Docker

**Para activar CI:**

```bash
# Inicializar repo (si no existe)
git init
git add .
git commit -m "Initial commit - Clase 2 MLflow"

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

**Error: Scripts `.sh` no ejecutan**

```bash
# Ejecutar explícitamente con bash
bash scripts/run_experiments.sh
bash scripts/serve_model.sh
```

**Error: MLflow UI no abre**

```bash
# Verificar que el puerto 5000 no esté ocupado
netstat -ano | findstr :5000

# Usar otro puerto si hace falta
mlflow ui --port 5001
```

**Error: curl no encontrado**

```bash
# Git Bash incluye curl, si no funciona:
# Descargar desde: https://curl.se/windows/
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

**Error: Scripts no ejecutan**

```bash
# Dar permisos de ejecución
chmod +x scripts/*.sh

# Verificar
ls -l scripts/
```

**Error: MLflow UI no abre**

```bash
# Verificar que el puerto 5000 no esté ocupado
lsof -i :5000

# Usar otro puerto si hace falta
mlflow ui --port 5001
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
python src/train_mlflow.py
bash scripts/run_experiments.sh
mlflow ui --port 5000 &
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
python src/train_mlflow.py
bash scripts/run_experiments.sh
mlflow ui --port 5000 &
docker build -t demo-ml:local .
docker run --rm -v "$PWD:/app" demo-ml:local
```

---

## Salidas Esperadas Resumidas

| Comando | Salida Esperada |
|---------|----------------|
| `pytest -q` | `5 passed` |
| `python src/train.py` | `acc: 0.9667` |
| `python src/train_mlflow.py` | `Run ID: ...` + `acc: 0.9667` |
| `bash scripts/run_experiments.sh` | 3 runs con métricas |
| `mlflow ui --port 5000` | UI en `http://127.0.0.1:5000` |
| `curl` a modelo servido | `{"predictions": [0]}` (200 OK) |
| `docker run ...` | `acc: 0.9667` |
| `pre-commit run --all-files` | `Passed` (black, ruff) |
| GitHub Actions | ✓ Badge verde |

---

## Flujo de Trabajo Recomendado

1. **Entrenar modelo básico:** `python src/train.py`
2. **Entrenar con MLflow:** `python src/train_mlflow.py`
3. **Levantar UI:** `mlflow ui --port 5000`
4. **Ejecutar experimentos:** `bash scripts/run_experiments.sh`
5. **Comparar en UI:** Abrir navegador → `http://127.0.0.1:5000`
6. **Seleccionar mejor modelo:** Ordenar por métrica en UI
7. **Servir modelo:** `bash scripts/serve_model.sh`
8. **Probar predicciones:** `curl` con datos de prueba

---

## Próximos Pasos

Ver **ONBOARDING.md** para:
- Activar GitHub Copilot (Student Pack)
- Configuración inicial del entorno
- Chequeos de validación completos
- Troubleshooting específico por OS

