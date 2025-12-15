# ============================================================================
# EKS CLUSTER
# ============================================================================

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  version  = local.k8s_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  # Networking
  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.control_plane.id]
  }

  # Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # OIDC para IRSA
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name = "${local.cluster_name}-eks"
  }
}

# ============================================================================
# EKS NODE GROUP (Worker Nodes)
# ============================================================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.nodes_role.arn
  subnet_ids      = aws_subnet.private[*].id
  version         = local.k8s_version

  # Tamaño y escala
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  # Instancias
  instance_types = [var.node_instance_type]

  # Actualización
  update_config {
    max_unavailable_percentage = 33
  }

  # Disk size
  disk_size = 50

  # AMI Type
  ami_type = "AL2_x86_64"

  # Capacidad type
  capacity_type = "ON_DEMAND"

  # Labels para scheduling
  labels = {
    Name        = "${local.cluster_name}-worker"
    Environment = var.environment
  }

  # Tags para ASG
  tags = {
    Name = "${local.cluster_name}-nodes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# ============================================================================
# ADDONS (CNI, CoreDNS, kube-proxy, ebs-csi-driver)
# ============================================================================

# VPC CNI (Networking)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = "v1.18.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn = aws_iam_role.nodes_role.arn

  tags = {
    Name = "${local.cluster_name}-vpc-cni"
  }
}

# CoreDNS (DNS)
resource "aws_eks_addon" "coredns" {
  cluster_name            = aws_eks_cluster.main.name
  addon_name              = "coredns"
  addon_version           = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.cluster_name}-coredns"
  }

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy (Networking)
resource "aws_eks_addon" "kube_proxy" {
  cluster_name            = aws_eks_cluster.main.name
  addon_name              = "kube-proxy"
  addon_version           = "v1.32.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${local.cluster_name}-kube-proxy"
  }

  depends_on = [aws_eks_node_group.main]
}

# EBS CSI Driver (Storage)
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.29.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn = aws_iam_role.nodes_role.arn

  tags = {
    Name = "${local.cluster_name}-ebs-csi-driver"
  }

  depends_on = [aws_eks_node_group.main]
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = aws_eks_node_group.main.arn
}

