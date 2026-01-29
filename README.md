# InfoLine - Infrastructure DevOps

Projet ECF - TP Administrateur Système DevOps 

## 📋 Description

InfoLine est une plateforme web d'actualités sur les technologies sportives avec e-commerce intégré. Ce dépôt contient l'infrastructure as code (IaC) pour déployer l'environnement sur AWS.

## 📁 Structure du Projet

```
terraform/
├── main.tf              # Provider AWS et versions
├── variables.tf         # Déclaration des variables
├── vpc.tf               # Réseau (VPC, Subnet, IGW, Routes)
├── security-groups.tf   # Règles de pare-feu
├── iam.tf               # Rôles et politiques IAM
├── s3.tf                # Bucket S3 pour backups
├── ec2.tf               # Instance EC2 Spot + Elastic IP
├── outputs.tf           # Valeurs de sortie
├── terraform.tfvars     # Valeurs personnalisées
└── scripts/
    └── user-data.sh     # Script d'initialisation (K3s, Helm, ELK...)
```
## 🛠️ Technologies

| Composant | Technologie |
|-----------|-------------|
| IaC | Terraform |
| Cloud | AWS |
| Kubernetes | K3s |
| Ingress | NGINX Ingress Controller |
| Certificats | Cert-Manager + Let's Encrypt |
| Monitoring | ELK Stack (Elasticsearch, Kibana, Filebeat) |
| Base de données | PostgreSQL |
| Stockage | AWS EBS gp3 |
| Accès sécurisé | AWS SSM Session Manager |

## ⚙️ Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configuré
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) (optionnel)

## 📚 Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [K3s Documentation](https://docs.k3s.io/)
- [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager](https://cert-manager.io/docs/)
- [Elastic Helm Charts](https://github.com/elastic/helm-charts)


