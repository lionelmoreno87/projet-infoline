# Général

project_name = "infoline"
environment  = "dev"

# AWS

aws_region        = "eu-west-3"
availability_zone = "eu-west-3a"

# Réseau

vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# Sécurité

allowed_ingress_cidr = "0.0.0.0/0"

# Instance EC2

instance_type    = "t3.medium"
root_volume_size = 30

# S3 Backups

backup_retention_days = 30

# Accès K3s API pour CI/CD

enable_k3s_api_access = true
allowed_k3s_api_cidr  = "0.0.0.0/0"


