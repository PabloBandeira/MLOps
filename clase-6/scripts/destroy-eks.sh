#!/bin/bash

################################################################################
# Script: destroy-eks.sh
# Descripción: Destruye toda la infraestructura en AWS
# ADVERTENCIA: ¡ESTO BORRARÁ TODO! No se puede deshacer fácilmente
# Uso: ./scripts/destroy-eks.sh
################################################################################

set -e

echo "============================================================================"
echo "⚠️  DESTRUYENDO TODA LA INFRAESTRUCTURA EN AWS"
echo "============================================================================"
echo ""
echo "🔴 ADVERTENCIA:"
echo "   - Esto eliminará el clúster EKS"
echo "   - Se eliminarán todos los datos persistentes"
echo "   - Se eliminarán los load balancers"
echo "   - Se eliminarán los recursos de almacenamiento"
echo "   - ¡ESTO NO SE PUEDE DESHACER!"
echo ""

read -p "¿Realmente deseas continuar? Escribe 'SÍ' para confirmar: " confirmation

if [ "$confirmation" != "SÍ" ] && [ "$confirmation" != "SI" ]; then
    echo "❌ Operación cancelada"
    exit 0
fi

echo ""
echo "Iniciando destrucción en 5 segundos... (Ctrl+C para cancelar)"
sleep 5

echo ""
echo "🔨 Destruyendo recursos..."

cd "$(dirname "$0")/../infra"

terraform destroy -auto-approve

echo ""
echo "✅ Destrucción completada"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Verifica en AWS Console que no haya recursos restantes:"
echo "      - EC2 instances"
echo "      - Load Balancers"
echo "      - EBS volumes"
echo "      - RDS databases"
echo ""
echo "   2. Espera a que se procesen (puede tomar horas)"
echo ""
echo "   3. Revisa la factura del mes siguiente"
echo ""
echo "============================================================================"

