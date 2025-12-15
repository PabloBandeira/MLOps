# ============================================================================
# STORAGE - EBS VOLUMES Y STORAGE CLASSES
# ============================================================================

# Storage Class para volumes rápidos
resource "kubernetes_storage_class" "fast" {
  metadata {
    name = "fast"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  allow_volume_expansion = true

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
  }
}

# Storage Class para volumes estándar (default)
resource "kubernetes_storage_class" "standard" {
  metadata {
    name = "standard"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  allow_volume_expansion = true

  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
  }
}

# PersistentVolumeClaim para MLflow
resource "kubernetes_persistent_volume_claim" "mlflow_storage" {
  metadata {
    name = "mlflow-pvc"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.standard.metadata[0].name
    resources {
      requests = {
        storage = "${var.mlflow_volume_size}Gi"
      }
    }
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# PersistentVolumeClaim para Evidently
resource "kubernetes_persistent_volume_claim" "evidently_storage" {
  metadata {
    name = "evidently-pvc"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.standard.metadata[0].name
    resources {
      requests = {
        storage = "${var.evidently_volume_size}Gi"
      }
    }
  }

  depends_on = [aws_eks_addon.ebs_csi_driver]
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "mlflow_pvc_name" {
  description = "MLflow Persistent Volume Claim name"
  value       = kubernetes_persistent_volume_claim.mlflow_storage.metadata[0].name
}

output "evidently_pvc_name" {
  description = "Evidently Persistent Volume Claim name"
  value       = kubernetes_persistent_volume_claim.evidently_storage.metadata[0].name
}

