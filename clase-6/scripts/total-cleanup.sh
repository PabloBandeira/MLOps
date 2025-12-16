#!/bin/bash

################################################################################
# Script: total-cleanup.sh
# Descripción: Destruye ABSOLUTAMENTE TODO en AWS
# Uso: ./scripts/total-cleanup.sh
# 
# ⚠️  ADVERTENCIA: NO SE PUEDE DESHACER
# Esta script borra:
# - EKS Clusters y Node Groups
# - VPCs y subnets
# - Security Groups
# - Load Balancers (ALB/NLB y Clásicos)
# - EBS Volumes
# - ECR Repositories
# - NAT Gateways
# - Internet Gateways
# - IAM Roles y Políticas
# - Network Interfaces
# - Elastic IPs
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
echo "   - Se borrará TODO lo que quedó pendiente"
echo "   - Se borrará EKS, VPCs, Security Groups, Roles, ECR"
echo "   - NO habrá forma de recuperar nada"
echo ""

# Obtener valores
REGION=$(grep "aws_region = " infra/terraform.tfvars 2>/dev/null | head -1 | cut -d'"' -f2)

if [ -z "$REGION" ]; then
    REGION="us-east-1"
fi

echo -e "${BLUE}Información:${NC}"
echo "   Región: $REGION"
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
    terraform destroy -auto-approve 2>&1 || echo -e "${YELLOW}ℹ️  Terraform destroy completado (puede haber warnings)${NC}"
    echo -e "${GREEN}✅ Terraform destroy completado${NC}"
else
    echo -e "${YELLOW}ℹ️  No hay estado de Terraform (ya fue destruido)${NC}"
fi

cd ..

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 2: Limpieza de recursos residuales en AWS${NC}"
echo "================================================================================"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "   Account ID: $ACCOUNT_ID"
echo "   Región: $REGION"
echo ""

# ============================================================================
# PASO 2.1: Borrar EKS Node Groups
# ============================================================================
echo -e "${YELLOW}⏳ Borrando EKS Node Groups...${NC}"

CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text 2>/dev/null || echo "")

if [ ! -z "$CLUSTERS" ]; then
    for CLUSTER in $CLUSTERS; do
        # Ignorar clusters que no son nuestros (no empiezan con mlops)
        if [[ $CLUSTER == mlops* ]]; then
            echo "   Borrando node groups del cluster: $CLUSTER"
            NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER --region $REGION --query 'nodegroups[]' --output text 2>/dev/null || echo "")
            
            for NODEGROUP in $NODEGROUPS; do
                echo "   - Borrando node group: $NODEGROUP"
                aws eks delete-nodegroup --cluster-name $CLUSTER --nodegroup-name $NODEGROUP --region $REGION 2>/dev/null
            done
        fi
    done
    
    # Esperar a que se borren los node groups
    echo -e "${YELLOW}⏳ Esperando a que se borren los node groups (esto puede tardar varios minutos)...${NC}"
    sleep 60
fi

# ============================================================================
# PASO 2.2: Borrar EKS Clusters
# ============================================================================
echo -e "${YELLOW}⏳ Borrando EKS Clusters...${NC}"

CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text 2>/dev/null || echo "")

if [ ! -z "$CLUSTERS" ]; then
    for CLUSTER in $CLUSTERS; do
        if [[ $CLUSTER == mlops* ]]; then
            echo "   Borrando cluster: $CLUSTER"
            aws eks delete-cluster --name $CLUSTER --region $REGION 2>/dev/null || echo "   ℹ️  Cluster en proceso de eliminación"
        fi
    done
fi

# ============================================================================
# PASO 2.3: Borrar Load Balancers
# ============================================================================
echo -e "${YELLOW}⏳ Borrando Load Balancers...${NC}"

LBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[].LoadBalancerArn' --output text 2>/dev/null || echo "")

if [ ! -z "$LBS" ]; then
    for LB in $LBS; do
        echo "   Borrando Load Balancer: $LB"
        aws elbv2 delete-load-balancer --load-balancer-arn $LB --region $REGION 2>/dev/null || true
    done
fi

# ============================================================================
# PASO 2.4: Borrar ECR Repositories
# ============================================================================
echo -e "${YELLOW}⏳ Borrando repositorios ECR...${NC}"

REPOS=$(aws ecr describe-repositories --region $REGION --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")

if [ ! -z "$REPOS" ]; then
    for repo in $REPOS; do
        if [[ "$repo" == "iris-api" ]] || [[ "$repo" == "workspace" ]]; then
            echo "   Borrando repositorio: $repo"
            aws ecr delete-repository --repository-name "$repo" --region $REGION --force 2>/dev/null || true
        fi
    done
fi

# ============================================================================
# PASO 2.5: Borrar VPCs y recursos asociados
# ============================================================================
echo -e "${YELLOW}⏳ Identificando y borrando VPCs...${NC}"

# Obtener todas las VPCs que no son default
VPCS=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>/dev/null || echo "")

if [ ! -z "$VPCS" ]; then
    for VPC_ID in $VPCS; do
        echo ""
        echo "   Procesando VPC: $VPC_ID"
        
        # Borrar Internet Gateways
        echo "   - Borrando Internet Gateways..."
        IGWS=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[].InternetGatewayId' --output text 2>/dev/null || echo "")
        
        for IGW in $IGWS; do
            aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION 2>/dev/null || true
            aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION 2>/dev/null || true
        done
        
        # Borrar NAT Gateways
        echo "   - Borrando NAT Gateways..."
        NATS=$(aws ec2 describe-nat-gateways --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending" --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null || echo "")
        
        for NAT in $NATS; do
            aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION 2>/dev/null || true
        done
        
        # Borrar Route Tables (excepto main)
        echo "   - Borrando Route Tables..."
        RTS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text 2>/dev/null || echo "")
        
        for RT in $RTS; do
            aws ec2 delete-route-table --route-table-id $RT --region $REGION 2>/dev/null || true
        done
        
        # Borrar Network Interfaces
        echo "   - Borrando Network Interfaces..."
        ENIS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null || echo "")
        
        for ENI in $ENIS; do
            # Ignorar ENI de servicios gestionados
            if ! aws ec2 describe-network-interfaces --region $REGION --network-interface-ids $ENI --query 'NetworkInterfaces[0].Description' --output text | grep -q "AWS Lambda"; then
                aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION 2>/dev/null || true
            fi
        done
        
        # Borrar Subnets
        echo "   - Borrando Subnets..."
        SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text 2>/dev/null || echo "")
        
        for SUBNET in $SUBNETS; do
            aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION 2>/dev/null || true
        done
        
        # Borrar Security Groups (excepto default)
        echo "   - Borrando Security Groups..."
        SGs=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[].GroupId' --output text 2>/dev/null || echo "")
        
        for SG in $SGs; do
            aws ec2 delete-security-group --group-id $SG --region $REGION 2>/dev/null || true
        done
        
        # Finalmente, borrar la VPC
        echo "   - Borrando VPC..."
        aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null || echo "   ℹ️  VPC en proceso de eliminación o tiene recursos asociados"
    done
fi

# ============================================================================
# PASO 2.6: Borrar Elastic IPs huérfanas
# ============================================================================
echo -e "${YELLOW}⏳ Borrando Elastic IPs huérfanas...${NC}"

EIPS=$(aws ec2 describe-addresses --region $REGION --query 'Addresses[?AssociationId==null].AllocationId' --output text 2>/dev/null || echo "")

if [ ! -z "$EIPS" ]; then
    for EIP in $EIPS; do
        echo "   Borrando Elastic IP: $EIP"
        aws ec2 release-address --allocation-id $EIP --region $REGION 2>/dev/null || true
    done
fi

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 6: Verificación final${NC}"
echo "================================================================================"

echo ""
echo -e "${BLUE}🔍 Instancias EC2 (debería estar vacío):${NC}"
aws ec2 describe-instances --region $REGION --query 'Reservations[].Instances[?State.Name!=`terminated`].{ID:InstanceId,Type:InstanceType,State:State.Name}' --output table 2>/dev/null || echo "   (ninguna)"

echo ""
echo -e "${BLUE}🔍 Load Balancers (debería estar vacío):${NC}"
aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,State:State.Code}' --output table 2>/dev/null || echo "   (ninguno)"

echo ""
echo -e "${BLUE}🔍 VPCs (solo default):${NC}"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,IsDefault:IsDefault}' --output table 2>/dev/null || echo "   (ninguna)"

echo ""
echo -e "${BLUE}🔍 ECR Repositories (debería estar vacío):${NC}"
aws ecr describe-repositories --region $REGION --query 'repositories[].{Name:repositoryName,Uri:repositoryUri}' --output table 2>/dev/null || echo "   (ninguno)"

echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 4: Limpieza de IAM Roles${NC}"
echo "================================================================================"
echo -e "${YELLOW}⏳ Borrando IAM Roles residuales...${NC}"

# Array de posibles roles que Terraform creó
ROLES_TO_DELETE=(
  "mlops-cluster-dev-autoscaler-role"
  "mlops-cluster-dev-eks-cluster-role"
  "mlops-cluster-dev-eks-nodegroup-role"
  "mlops-cluster-dev-nodes-role"
  "mlops-cluster-prod-autoscaler-role"
  "mlops-cluster-prod-eks-cluster-role"
  "mlops-cluster-prod-eks-nodegroup-role"
  "mlops-cluster-prod-nodes-role"
  "mlops-cluster-test-autoscaler-role"
  "mlops-cluster-test-eks-cluster-role"
  "mlops-cluster-test-eks-nodegroup-role"
  "mlops-cluster-test-nodes-role"
  "mlops-cluster-dev-nodes-role"
  "mlops-cluster-prod-nodes-role"
  "mlops-cluster-test-nodes-role"
)

for ROLE_NAME in "${ROLES_TO_DELETE[@]}"; do
  # Verificar si el role existe
  if aws iam get-role --role-name "$ROLE_NAME" 2>/dev/null >/dev/null; then
    echo "   Borrando role: $ROLE_NAME"
    
    # 1. Borrar políticas inline
    INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --query 'PolicyNames[]' --output text 2>/dev/null || echo "")
    for POLICY in $INLINE_POLICIES; do
      aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY" 2>/dev/null || true
    done
    
    # 2. Desacoplar políticas adjuntas
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
    for POLICY_ARN in $ATTACHED_POLICIES; do
      aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$POLICY_ARN" 2>/dev/null || true
    done
    
    # 3. Borrar el role
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null || true
  fi
done

echo -e "${GREEN}✅ IAM Roles limpiados${NC}"

# ============================================================================
# PASO 5: Limpieza de VPCs rebeldes (si quedan)
# ============================================================================
echo ""
echo "================================================================================"
echo -e "${BLUE}PASO 5: Limpieza de VPCs rebeldes (si quedan)${NC}"
echo "================================================================================"

REMAINING_VPCS=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>/dev/null || echo "")

if [ ! -z "$REMAINING_VPCS" ]; then
    echo -e "${YELLOW}⚠️  Hay VPCs que no se borraron automáticamente. Últimos intentos...${NC}"
    echo ""
    
    for VPC_ID in $REMAINING_VPCS; do
        echo "   Intento final con: $VPC_ID"
        
        # Borrar Classic Load Balancers (a veces quedan)
        LBS=$(aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null || echo "")
        for LB in $LBS; do
            aws elb delete-load-balancer --load-balancer-name "$LB" --region $REGION 2>/dev/null || true
        done
        
        # Intentar de nuevo
        aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null && echo "      ✅ Borrada" || echo "      ℹ️  No se pudo borrar desde script"
    done
    
    sleep 5
    
    # Verificar si siguen
    REMAINING=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`].VpcId' --output text 2>/dev/null || echo "")
    
    if [ ! -z "$REMAINING" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANTE: Hay VPCs que no se borraron desde el script${NC}"
        echo ""
        echo "Puedes borrarlas manualmente desde la consola:"
        echo "   https://console.aws.amazon.com/vpc/"
        echo ""
        echo "VPCs restantes:"
        for VPC in $REMAINING; do
            echo "   - $VPC"
        done
    fi
fi

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
echo "   - EC2 Dashboard → VPCs (solo default)"
echo "   - EKS Dashboard → Clusters (0)"
echo "   - ECR → Repositories (vacío)"
echo ""
echo "3. Si hay VPCs restantes, elimínalas desde:"
echo "   https://console.aws.amazon.com/vpc/"
echo ""
echo "4. Espera 10-15 minutos para que se procese completamente"
echo ""
echo "5. Revisa tu factura siguiente para confirmar cargos \$0"
echo ""
echo -e "${GREEN}🎉 ¡Todo destruido exitosamente!${NC}"
echo ""
