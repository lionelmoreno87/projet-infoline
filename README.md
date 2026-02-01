# InfoLine - Infrastructure DevOps

Projet ECF - TP Administrateur Système DevOps 

## 📋 Description

InfoLine est une plateforme web d'actualités sur les technologies sportives. Ce dépôt contient l'infrastructure as code pour déployer l'environnement sur AWS.

## 📁 Structure du Projet

```
terraform/
├── ec2.tf
├── iam.tf
├── lambda.tf
├── main.tf
├── outputs.tf
├── s3.tf
├── scripts
│   └── user-data.sh
├── security-groups.tf
├── terraform.tfvars
├── variables.tf
└── vpc.tf

```

## 🛠️ Technologies

| Composant       | Technologie                                 |
| --------------- | ------------------------------------------- |
| IaC             | Terraform                                   |
| Cloud           | AWS                                         |
| Kubernetes      | K3s                                         |
| Ingress         | NGINX Ingress Controller                    |
| Certificats     | Cert-Manager + Let's Encrypt                |
| Monitoring      | ELK Stack (Elasticsearch, Kibana, Filebeat) |
| Base de données | PostgreSQL                                  |
| Stockage        | AWS EBS gp3                                 |
| Accès sécurisé  | AWS SSM Session Manager                     |

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
