# InfoLine - Infrastructure DevOps

Projet ECF - TP Administrateur Système DevOps (Studi - Hiver 2025)

## Description

InfoLine est une plateforme web spécialisée dans l'actualité des technologies sportives, permettant la consultation d'annonces et la vente de produits connectés. Ce dépôt contient l'ensemble du code source : infrastructure as code, applications conteneurisées, pipelines CI/CD et stack de monitoring.

## Structure du projet

```
projet-infoline/
│
├── terraform/                    # Infrastructure as Code (AT1)
│   ├── main.tf                   # Provider AWS et configuration
│   ├── variables.tf              # Variables typées et documentées
│   ├── terraform.tfvars          # Valeurs des variables
│   ├── vpc.tf                    # VPC, subnet, internet gateway
│   ├── security-groups.tf        # Règles de pare-feu
│   ├── ec2.tf                    # Instance EC2 + Elastic IP
│   ├── iam.tf                    # Rôles et politiques IAM
│   ├── s3.tf                     # Bucket S3 pour les backups
│   ├── lambda.tf                 # Fonction Lambda + API Gateway
│   ├── outputs.tf                # Valeurs de sortie
│   ├── scripts/
│   │   └── user-data.sh          # K3s, Helm, ELK
│   └── lambda/
│       └── login-placeholder.zip # Code de la fonction Lambda
│
├── api-infoline/                 # Backend Java (AT2)
│   ├── src/
│   │   ├── main/java/com/infoline/api/
│   │   │   ├── ApiApplication.java
│   │   │   └── HelloController.java
│   │   └── test/
│   ├── Dockerfile                # Multi-stage build (Maven + JRE Alpine)
│   └── pom.xml
│
├── frontend-infoline/            # Frontend Angular (AT2)
│   ├── src/
│   ├── Dockerfile                # Multi-stage build (Node + Nginx)
│   └── package.json
│
├── k8s/                          # Manifestes Kubernetes
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
│
└── .github/workflows/            # Pipelines CI/CD (AT2)
    ├── deploy.yml                # Pipeline API (build, push, deploy)
    └── deploy-frontend.yml       # Pipeline Frontend (build, push, deploy)
```

## Technologies

| Composant        | Technologie                                 |
| ---------------- | ------------------------------------------- |
| IaC              | Terraform                                   |
| Cloud            | AWS (EC2, Lambda, API Gateway, S3, SSM)     |
| Kubernetes       | K3s v1.34                                   |
| Backend          | Java 17, Spring Boot 4.0.1, Maven           |
| Frontend         | Angular 19, Node.js, Nginx                  |
| Conteneurisation | Docker (multi-stage builds)                 |
| CI/CD            | GitHub Actions                              |
| Ingress          | NGINX Ingress Controller                    |
| Certificats      | Cert-Manager + Let's Encrypt                |
| Monitoring       | ELK Stack (Elasticsearch, Kibana, Filebeat) |
| Base de données  | PostgreSQL + PVC                             |
| Stockage         | AWS EBS gp3                                 |
| Accès sécurisé   | AWS SSM Session Manager (pas de SSH)        |

## Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configuré avec les credentials
- [Docker](https://docs.docker.com/get-docker/) pour le build des images
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) 

## Déploiement

### 1. Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Terraform crée 32 ressources : VPC, EC2 avec K3s, Lambda, API Gateway, S3, IAM, Security Groups, Elastic IP.

### 2. Configuration du kubeconfig

```bash
# Connexion à l'instance via SSM
aws ssm start-session --target <INSTANCE_ID> --region eu-west-3

# Récupération et encodage du kubeconfig pour GitHub Actions
sudo cp /etc/rancher/k3s/k3s.yaml /tmp/kubeconfig.yaml
sudo sed -i 's/127.0.0.1/<ELASTIC_IP>/g' /tmp/kubeconfig.yaml
sudo cat /tmp/kubeconfig.yaml | base64 -w 0
```

Le kubeconfig encodé est stocké dans le secret GitHub `KUBE_CONFIG`.

### 3. Déploiement des applications (automatique via CI/CD)

Un simple `git push origin main` déclenche les deux pipelines :

- **API Pipeline** : Build Maven, tests, build Docker, push Docker Hub, deploy K3s
- **Frontend Pipeline** : Build Angular, tests, build Docker, push Docker Hub, deploy K3s

## Pipelines CI/CD

Chaque pipeline comporte trois étapes séquentielles :

```
git push → Build and Test → Build and Push Docker Image → Deploy to K3s Cluster

```

Les images Docker sont publiées sur Docker Hub :
- `lionelmoreno/infoline-api:latest`
- `lionelmoreno/infoline-frontend:latest`

## Monitoring (ELK Stack)

La stack ELK est déployée dans le namespace `monitoring` via Helm :

- **Elasticsearch 7.17.18** : stockage et indexation des logs (StatefulSet, 1 réplica)
- **Kibana** : interface de visualisation, accessible via ingress nip.io
- **Filebeat** : collecte des logs de tous les conteneurs (DaemonSet)

### Accès à Kibana

```
http://kibana.<ELASTIC_IP>.nip.io

```

### Exemples de requêtes KQL

```
# Logs de l'API
message: "infoline-api-service"

# Logs du frontend
message: "infoline-frontend-service"

```

## Vérifications utiles

```bash
# État du cluster
sudo kubectl get nodes

# Pods applicatifs
sudo kubectl get pods

# Services
sudo kubectl get svc

# Ingress
sudo kubectl get ingress

# Stack monitoring
sudo kubectl get pods -n monitoring

# Health check Elasticsearch
sudo kubectl exec -n monitoring elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health
```

## Sécurité

- Aucun port SSH ouvert : accès uniquement via AWS SSM Session Manager
- Rôle IAM avec principe du moindre privilège
- Bucket S3 avec chiffrement AES256 et blocage de l'accès public
- Versioning activé sur le bucket S3
- Security Group restrictif (ports 80, 443, 6443 uniquement)

## Documentation de référence

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [K3s Documentation](https://docs.k3s.io/)
- [Spring Boot](https://spring.io/projects/spring-boot)
- [Angular CLI](https://angular.dev/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager](https://cert-manager.io/docs/)
- [Elastic Helm Charts](https://github.com/elastic/helm-charts)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
