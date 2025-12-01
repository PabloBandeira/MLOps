# ========================================
# CLÚSTER KIND
# ========================================
# 
# NOTA IMPORTANTE:
# El clúster Kind se crea manualmente con el script setup.sh
# Terraform solo gestiona los recursos DENTRO del clúster
#
# El clúster se crea con: 
#   kind create cluster --name mlops-cluster --config kind-config.yaml
# 
# Esto evita conflictos de gestión y es el patrón recomendado para Kind
# porque es una herramienta de desarrollo local.
# 
# Terraform gestiona: Deployments, Services, ConfigMaps, etc.
