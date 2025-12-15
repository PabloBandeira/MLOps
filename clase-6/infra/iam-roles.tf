# ============================================================================
# IAM ROLES Y POLÍTICAS
# ============================================================================

# Role para EKS Control Plane
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.cluster_name}-eks-cluster-role"
  }
}

# Attach política de permisos básicos para EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach política de VPC CNI
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# ============================================================================
# IAM Role para Worker Nodes
# ============================================================================

resource "aws_iam_role" "nodes_role" {
  name = "${local.cluster_name}-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.cluster_name}-nodes-role"
  }
}

# Política básica para nodos EKS
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes_role.name
}

# Política CNI para networking
resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes_role.name
}

# Política para ECR (pull de imágenes privadas)
resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes_role.name
}

# Política para SSM (acceso remoto a nodos)
resource "aws_iam_role_policy_attachment" "nodes_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes_role.name
}

# Política para CloudWatch Logs
resource "aws_iam_role_policy_attachment" "nodes_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.nodes_role.name
}

# Instance Profile para nodos
resource "aws_iam_instance_profile" "nodes_profile" {
  name = "${local.cluster_name}-nodes-profile"
  role = aws_iam_role.nodes_role.name
}

# ============================================================================
# IAM Role para Service Accounts (IRSA)
# ============================================================================

# OIDC Provider (para federar identidades)
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = {
    Name = "${local.cluster_name}-oidc"
  }
}

# Construcción del provider ARN
locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.cluster.arn
  oidc_provider_url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Service Account Role para MLflow
resource "aws_iam_role" "mlflow_sa_role" {
  name = "${local.cluster_name}-mlflow-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(local.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:default:mlflow-sa"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.cluster_name}-mlflow-sa-role"
  }
}

# Política para MLflow (ejemplo: acceso a S3)
resource "aws_iam_role_policy" "mlflow_s3_policy" {
  name = "${local.cluster_name}-mlflow-s3-policy"
  role = aws_iam_role.mlflow_sa_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = ["arn:aws:s3:::mlflow-*/*", "arn:aws:s3:::mlflow-*"]
      }
    ]
  })
}

# ============================================================================
# IAM Role para Autoscaler
# ============================================================================

resource "aws_iam_role" "autoscaler_role" {
  name = "${local.cluster_name}-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(local.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.cluster_name}-autoscaler-role"
  }
}

# Política para Cluster Autoscaler
resource "aws_iam_role_policy" "autoscaler_policy" {
  name = "${local.cluster_name}-autoscaler-policy"
  role = aws_iam_role.autoscaler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

