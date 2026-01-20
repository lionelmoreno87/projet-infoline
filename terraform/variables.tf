# Variables Générales

variable "project_name" {
  description = "Nom du projet (utilisé pour nommer les ressources)"
  type        = string
  default     = "infoline"
}

variable "environment" {
  description = "Environnement de déploiement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Variables AWS

variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3" # Paris
}

# Variables Instance EC2

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Taille du volume racine en Go"
  type        = number
  default     = 30
}

# Variables Réseau (VPC)

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block pour le subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zone de disponibilité AWS"
  type        = string
  default     = "eu-west-3a"
}

# Variables Sécurité (Security Groups)

variable "allowed_ingress_cidr" {
  description = "CIDR autorisé pour l'accès HTTP/HTTPS (0.0.0.0/0 pour public)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_k3s_api_access" {
  description = "Activer l'accès API kubectl"
  type        = bool
  default     = false
}

variable "allowed_k3s_api_cidr" {
  description = "CIDR autorisé pour l'accès API EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "domain_name" {
  description = "Nom de domaine pour l'application"
  type        = string
  default     = ""
}