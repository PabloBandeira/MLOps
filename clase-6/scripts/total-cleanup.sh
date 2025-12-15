#!/bin/bash

################################################################################
# Script: total-cleanup.sh
# Descripción: Destruye ABSOLUTAMENTE TODO en AWS
# Uso: ./scripts/total-cleanup.sh
# 
# ⚠️  ADVERTENCIA: NO SE PUEDE DESHACER
# Esta script borra:
# - VPC
# - Subnets
# - Security Groups
# - EKS Cluster
# - Nodos EC2
# - Load Balancers
# - EBS Volumes
# - ECR Repositories
# - IAM Roles
# - ABSOLUTAMENTE TODO
################################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "================================================================================"
echo -e "${RED}🔴 DESTRUCCIÓN TOTAL - BORRARÁ ABSOLUTAMENTE TODO${NC}"
echo "================================================================================"
echo ""
echo -e "${RED}⚠️  ADVERTENCIA CRÍTICA:${NC}"
echo "   - Esto NO se puede deshacer"
echo "   - Se borrará TODO lo que Terraform creó"
echo "   - Se borrará ECR repositories"
echo "   - Se borrará todas las imágenes"
echo "   - Se borrará los volúmenes EBS"
echo "   - NO habrá forma de recuperar datos"
echo ""

# Obtener valores
REGION=$(grep "aws_region = " infra/terraform.tfvars 2>/dev/null | head -1 | cut -d'"' -f2)
CLUSTER_NAME=$(grep "cluster_name = " infra/terraform.tfvars 2>/dev/null | head -1 | cut -d'"' -f2)

if [ -z "$REGION" ]; then
    REGION="us-east-1"
fi

if [ -z "$CLUSTER_NAME" ]; then
    CLUSTER_NAME="mlops-cluster-prod"
fi

echo -e "${BLUE}Información:${NC}"
echo "   Región: $REGION"
echo "   Cluster: $CLUSTER_NAME"
echo ""

# Pedir confirmación triple
read -p "¿Estás COMPLETAMENTE seguro? (escribe 'DESTRUIR TODO'): " confirmation1

if [ "$confirmation1" != "DESTRUIR TODO" ]; then
    echo -e "${GREEN}✅ Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${RED}ÚLTIMA OPORTUNIDAD${NC}"
read -p "¿REALMENTE quieres destruir TODO? (escribe 'SÍ, DESTRUIR'): " confirmation2

if [ "$confirmation2" != "SÍ, DESTRUIR" ] && [ "$confirmation2" != "SI, DESTRUIR" ]; then
    echo -e "${GREEN}✅ Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Iniciando destrucción en 10 segundos... (Ctrl+C para cancelar)${NC}"
for i in {10..1}; do
    echo -n "$i... "
    sleep 1
done
echo ""

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 1: Destruyendo recursos Terraform${NC}"
echo "================================================================================"

cd infra

if [ -f "terraform.tfstate" ]; then
    echo -e "${YELLOW}⏳ Ejecutando terraform destroy...${NC}"
    terraform destroy -auto-approve
    echo -e "${GREEN}✅ Terraform destroy completado${NC}"
else
    echo -e "${YELLOW}ℹ️  No hay estado de Terraform (ya fue destruido)${NC}"
fi

cd ..

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 2: Borrando repositorios ECR${NC}"
echo "================================================================================"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "   Account ID: $ACCOUNT_ID"
echo "   Región: $REGION"
echo ""

# Obtener lista de repositorios
REPOS=$(aws ecr describe-repositories --region $REGION --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")

if [ -z "$REPOS" ]; then
    echo -e "${YELLOW}ℹ️  No hay repositorios ECR${NC}"
else
    for repo in $REPOS; do
        # Solo borrar los que creamos (iris-api, workspace)
        if [[ "$repo" == "iris-api" ]] || [[ "$repo" == "workspace" ]]; then
            echo -e "${YELLOW}⏳ Borrando repositorio: $repo${NC}"
            aws ecr delete-repository \
                --repository-name "$repo" \
                --region $REGION \
                --force 2>/dev/null && echo -e "${GREEN}   ✅ Borrado: $repo${NC}" || echo -e "${YELLOW}   ℹ️  Error o no existe: $repo${NC}"
        fi
    done
fi

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 3: Limpieza de recursos residuales${NC}"
echo "================================================================================"

# Limpiar imágenes no etiquetadas en ECR
echo -e "${YELLOW}⏳ Limpiando imágenes no etiquetadas en ECR...${NC}"
UNTAGGED_IMAGES=$(aws ecr list-images --repository-name iris-api --region $REGION --filter tagStatus=UNTAGGED --query 'imageIds[].imageDigest' --output text 2>/dev/null || echo "")

if [ ! -z "$UNTAGGED_IMAGES" ]; then
    for digest in $UNTAGGED_IMAGES; do
        aws ecr batch-delete-image \
            --repository-name iris-api \
            --image-ids imageDigest=$digest \
            --region $REGION 2>/dev/null || true
    done
    echo -e "${GREEN}✅ Imágenes no etiquetadas borradas${NC}"
else
    echo -e "${YELLOW}ℹ️  No hay imágenes no etiquetadas${NC}"
fi

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 4: Verificación final${NC}"
echo "================================================================================"

echo ""
echo -e "${BLUE}🔍 Instancias EC2 (debería estar vacío):${NC}"
aws ec2 describe-instances \
    --region $REGION \
    --query 'Reservations[].Instances[?State.Name!=`terminated`].{ID:InstanceId,Type:InstanceType,State:State.Name}' \
    --output table || echo "   ℹ️  No hay instancias o error en consulta"

echo ""
echo -e "${BLUE}🔍 Load Balancers (debería estar vacío):${NC}"
aws elbv2 describe-load-balancers \
    --region $REGION \
    --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code}' \
    --output table 2>/dev/null || echo "   ℹ️  No hay load balancers"

echo ""
echo -e "${BLUE}🔍 EBS Volumes (debería estar vacío excepto root):${NC}"
aws ec2 describe-volumes \
    --region $REGION \
    --query 'Volumes[?State==`available`].{ID:VolumeId,Size:Size,State:State,Tags:Tags[0].Value}' \
    --output table || echo "   ℹ️  Error en consulta"

echo ""
echo -e "${BLUE}🔍 Security Groups (debería estar vacío o solo defaults):${NC}"
aws ec2 describe-security-groups \
    --region $REGION \
    --query 'SecurityGroups[?GroupName!=`default`].{ID:GroupId,Name:GroupName,VPC:VpcId}' \
    --output table || echo "   ℹ️  Error en consulta"

echo ""
echo -e "${BLUE}🔍 ECR Repositories (debería estar vacío):${NC}"
aws ecr describe-repositories \
    --region $REGION \
    --query 'repositories[].{Name:repositoryName,URI:repositoryUri}' \
    --output table 2>/dev/null || echo "   ℹ️  No hay repositorios o error"

echo ""
echo -e "${BLUE}🔍 VPCs (debería estar solo 'default'):${NC}"
aws ec2 describe-vpcs \
    --region $REGION \
    --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,IsDefault:IsDefault}' \
    --output table || echo "   ℹ️  Error en consulta"

echo ""
echo "================================================================================"
echo -e "${GREEN}✅ DESTRUCCIÓN COMPLETADA${NC}"
echo "================================================================================"
echo ""
echo -e "${YELLOW}📝 PRÓXIMOS PASOS:${NC}"
echo ""
echo "1. Verifica manualmente en AWS Console:"
echo "   https://console.aws.amazon.com/"
echo ""
echo "2. En cada servicio, confirma que esté limpio:"
echo "   - EC2 Dashboard → Instances (0)"
echo "   - EC2 Dashboard → Load Balancers (0)"
echo "   - EC2 Dashboard → Volumes (vacío o solo defaults)"
echo "   - EC2 Dashboard → Security Groups (solo 'default')"
echo "   - EKS Dashboard → Clusters (0)"
echo "   - ECR → Repositories (vacío)"
echo ""
echo "3. Espera 10-15 minutos para que se procese completamente"
echo ""
echo "4. Revisa tu factura siguiente para confirmar cargos $0"
echo ""
echo -e "${GREEN}🎉 ¡Todo destruido exitosamente!${NC}"
echo ""
echo "================================================================================"

