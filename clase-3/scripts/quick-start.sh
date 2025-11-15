#!/bin/bash

# ====================================================================
# QUICK START SCRIPT - Clase 3: Model Monitoring
# ====================================================================
# Este script facilita el setup y ejecución de la clase
# Uso: bash scripts/quick-start.sh [opción]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ====================================================================
# FUNCIONES AUXILIARES
# ====================================================================

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ====================================================================
# VERIFICACIONES PREVIAS
# ====================================================================

verify_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado"
        echo "Instálalo desde: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose no está instalado"
        exit 1
    fi
    
    print_step "Docker y Docker Compose encontrados"
}

check_ports() {
    if lsof -i :5000 &> /dev/null; then
        print_error "Puerto 5000 ya está en uso"
        return 1
    fi
    
    if lsof -i :8000 &> /dev/null; then
        print_error "Puerto 8000 ya está en uso"
        return 1
    fi
    
    print_step "Puertos 5000 y 8000 disponibles"
}

# ====================================================================
# OPCIONES PRINCIPALES
# ====================================================================

start_services() {
    print_header "Iniciando Servicios"
    
    verify_docker
    check_ports
    
    echo "Construyendo imágenes (primera vez es más lenta)..."
    docker-compose build
    
    echo "Iniciando servicios..."
    docker-compose up -d
    
    print_step "Servicios iniciados"
    echo "Esperando 30 segundos a que se estabilicen..."
    sleep 30
    
    echo ""
    docker-compose ps
}

run_training() {
    print_header "Ejecutando Entrenamiento"
    
    if ! docker-compose ps | grep -q "monitoring-app.*running"; then
        print_error "El servicio monitoring no está corriendo"
        echo "Ejecuta primero: bash scripts/quick-start.sh start"
        exit 1
    fi
    
    print_step "Iniciando entrenamiento..."
    docker-compose exec monitoring python train_and_monitor.py
    
    print_step "¡Entrenamiento completado!"
}

run_drift_simulation() {
    print_header "Ejecutando Simulación de Drift"
    
    if ! docker-compose ps | grep -q "monitoring-app.*running"; then
        print_error "El servicio monitoring no está corriendo"
        exit 1
    fi
    
    print_step "Iniciando simulación de drift..."
    docker-compose exec monitoring python simulate_drift.py
    
    print_step "¡Simulación completada!"
}

show_logs() {
    print_header "Mostrando Logs en Vivo"
    
    docker-compose logs -f monitoring
}

stop_services() {
    print_header "Deteniendo Servicios"
    
    docker-compose down
    print_step "Servicios detenidos"
}

clean_all() {
    print_header "Limpieza Completa"
    
    print_warn "Esto eliminará TODOS los datos y volúmenes"
    read -p "¿Estás seguro? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker-compose down -v
        docker system prune -f
        print_step "Limpieza completada"
    else
        echo "Limpieza cancelada"
    fi
}

open_mlflow() {
    print_header "Abriendo MLflow UI"
    
    if command -v open &> /dev/null; then
        open http://localhost:5000
    else
        echo "Abre en tu navegador: http://localhost:5000"
    fi
}

open_evidently() {
    print_header "Abriendo Evidently Dashboard"
    
    if command -v open &> /dev/null; then
        open http://localhost:8000
    else
        echo "Abre en tu navegador: http://localhost:8000"
    fi
}

bash_shell() {
    print_header "Abriendo Shell del Contenedor"
    
    docker-compose exec monitoring bash
}

status() {
    print_header "Estado de Servicios"
    
    docker-compose ps
    
    echo ""
    echo "Interfaces web:"
    echo "  MLflow:    http://localhost:5000"
    echo "  Evidently: http://localhost:8000"
}

help_menu() {
    print_header "Ayuda - Opciones Disponibles"
    
    cat << EOF

Uso: bash scripts/quick-start.sh [opción]

OPCIONES:
  start           Inicia todos los servicios
  train           Ejecuta entrenamiento del modelo
  drift           Simula diferentes tipos de drift
  logs            Muestra logs en tiempo real
  stop            Detiene los servicios
  clean           Limpia todo (⚠️ elimina datos)
  
  mlflow          Abre MLflow UI (http://localhost:5000)
  evidently       Abre Evidently Dashboard (http://localhost:8000)
  bash            Abre shell en el contenedor monitoring
  status          Muestra estado de servicios
  
  help            Muestra esta ayuda

FLUJO TÍPICO:
  1. bash scripts/quick-start.sh start    # Iniciar servicios
  2. bash scripts/quick-start.sh train    # Entrenar modelo
  3. bash scripts/quick-start.sh mlflow   # Ver resultados
  4. bash scripts/quick-start.sh drift    # Simular drift
  5. bash scripts/quick-start.sh stop     # Detener

EOF
}

# ====================================================================
# MAIN
# ====================================================================

main() {
    case "${1:-help}" in
        start)
            start_services
            ;;
        train)
            run_training
            ;;
        drift)
            run_drift_simulation
            ;;
        logs)
            show_logs
            ;;
        stop)
            stop_services
            ;;
        clean)
            clean_all
            ;;
        mlflow)
            open_mlflow
            ;;
        evidently)
            open_evidently
            ;;
        bash)
            bash_shell
            ;;
        status)
            status
            ;;
        help)
            help_menu
            ;;
        *)
            print_error "Opción no reconocida: $1"
            help_menu
            exit 1
            ;;
    esac
}

# Ejecutar
main "$@"

