#!/bin/bash

REGION="us-east-1"

echo ""
echo "================================================================================"
echo "🔍 VERIFICACIÓN COMPLETA DE LIMPIEZA EN AWS"
echo "================================================================================"
echo ""

REGION=$(grep "aws_region = " infra/terraform.tfvars 2>/dev/null | head -1 | cut -d'"' -f2)
if [ -z "$REGION" ]; then
    REGION="us-east-1"
fi

echo "Región: $REGION"
echo ""

# Función para verificar si hay recursos
check_resource() {
    local name=$1
    local count=$2
    
    if [ "$count" -eq 0 ]; then
        echo "   ✅ $name: LIMPIO"
    else
        echo "   ❌ $name: $count recurso(s) encontrado(s)"
    fi
}

# ============================================================================
# 1. EKS Clusters
# ============================================================================
echo "1️⃣  EKS CLUSTERS"
EKS_CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters[]' --output text 2>/dev/null | wc -w)
check_resource "EKS Clusters" "$EKS_CLUSTERS"

# ============================================================================
# 2. Load Balancers (ALB/NLB)
# ============================================================================
echo ""
echo "2️⃣  LOAD BALANCERS (ALB/NLB)"
LBS=$(aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[]' --output text 2>/dev/null | wc -w)
check_resource "Load Balancers ALB/NLB" "$LBS"

# ============================================================================
# 3. Classic Load Balancers
# ============================================================================
echo ""
echo "3️⃣  LOAD BALANCERS (CLÁSICOS)"
CLASSIC_LBS=$(aws elb describe-load-balancers --region $REGION --query 'LoadBalancerDescriptions[]' --output text 2>/dev/null | wc -w)
check_resource "Load Balancers Clásicos" "$CLASSIC_LBS"

# ============================================================================
# 4. VPCs (no-default)
# ============================================================================
echo ""
echo "4️⃣  VPCs"
VPCS=$(aws ec2 describe-vpcs --region $REGION --query 'Vpcs[?IsDefault==`false`]' --output text 2>/dev/null | wc -w)
check_resource "VPCs no-default" "$VPCS"

# ============================================================================
# 5. Subnets
# ============================================================================
echo ""
echo "5️⃣  SUBNETS"
SUBNETS=$(aws ec2 describe-subnets --region $REGION --query 'Subnets[?MapPublicIpOnLaunch==`true`||MapPublicIpOnLaunch==`false`]' --output text 2>/dev/null | wc -w)
check_resource "Subnets personalizadas" "$SUBNETS"

# ============================================================================
# 6. Security Groups (no-default)
# ============================================================================
echo ""
echo "6️⃣  SECURITY GROUPS"
SGs=$(aws ec2 describe-security-groups --region $REGION --query 'SecurityGroups[?GroupName!=`default`]' --output text 2>/dev/null | wc -w)
check_resource "Security Groups no-default" "$SGs"

# ============================================================================
# 7. ECR Repositories
# ============================================================================
echo ""
echo "7️⃣  ECR REPOSITORIES"
ECR_REPOS=$(aws ecr describe-repositories --region $REGION --query 'repositories[]' --output text 2>/dev/null | wc -w)
check_resource "ECR Repositories" "$ECR_REPOS"

# ============================================================================
# 8. EC2 Instances (no-terminated)
# ============================================================================
echo ""
echo "8️⃣  EC2 INSTANCES"
INSTANCES=$(aws ec2 describe-instances --region $REGION --query 'Reservations[].Instances[?State.Name!=`terminated`]' --output text 2>/dev/null | wc -w)
check_resource "EC2 Instances activas" "$INSTANCES"

# ============================================================================
# 9. EBS Volumes (no-available vacío)
# ============================================================================
echo ""
echo "9️⃣  EBS VOLUMES"
VOLUMES=$(aws ec2 describe-volumes --region $REGION --query 'Volumes[?State==`in-use`||State==`creating`]' --output text 2>/dev/null | wc -w)
check_resource "EBS Volumes en uso" "$VOLUMES"

# ============================================================================
# 10. Elastic IPs (allocated)
# ============================================================================
echo ""
echo "🔟 ELASTIC IPs"
EIPS=$(aws ec2 describe-addresses --region $REGION --query 'Addresses[?AssociationId==null]' --output text 2>/dev/null | wc -w)
check_resource "Elastic IPs sin usar" "$EIPS"

# ============================================================================
# 11. NAT Gateways
# ============================================================================
echo ""
echo "1️⃣1️⃣  NAT GATEWAYS"
NATS=$(aws ec2 describe-nat-gateways --region $REGION --query 'NatGateways[?State!=`deleted`]' --output text 2>/dev/null | wc -w)
check_resource "NAT Gateways activos" "$NATS"

# ============================================================================
# 12. Internet Gateways
# ============================================================================
echo ""
echo "1️⃣2️⃣  INTERNET GATEWAYS"
IGWs=$(aws ec2 describe-internet-gateways --region $REGION --query 'InternetGateways[]' --output text 2>/dev/null | wc -w)
check_resource "Internet Gateways" "$IGWs"

# ============================================================================
# 13. IAM Roles (solo mlops)
# ============================================================================
echo ""
echo "1️⃣3️⃣  IAM ROLES"
IAM_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `mlops`)||contains(RoleName, `eks`)]' --output text 2>/dev/null | wc -w)
check_resource "IAM Roles (mlops/eks)" "$IAM_ROLES"

# ============================================================================
# RESUMEN
# ============================================================================
echo ""
echo "================================================================================"
echo "📊 RESUMEN"
echo "================================================================================"
echo ""

TOTAL=$((EKS_CLUSTERS + LBS + CLASSIC_LBS + VPCS + SUBNETS + SGs + ECR_REPOS + INSTANCES + VOLUMES + EIPS + NATS + IGWs + IAM_ROLES))

if [ "$TOTAL" -eq 0 ]; then
    echo -e "✅ \033[0;32mTODO ESTÁ LIMPIO - 100% LIMPIEZA COMPLETADA\033[0m"
    echo ""
    echo "Tu cuenta AWS está completamente libre de recursos."
    echo "✅ No hay cargos activos por infraestructura."
else
    echo -e "⚠️  \033[1;33mTODAVÍA HAY $TOTAL RECURSO(S)\033[0m"
    echo ""
    echo "Revisar la lista de arriba para ver qué quedó sin borrar."
fi

echo ""
echo "================================================================================"
echo ""

