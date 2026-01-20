#!/bin/bash

# Ce script s'exécute au premier démarrage de l'instance
# Installe : K3s, Helm, NGINX Ingress

set -e

# Variables (injectées par Terraform templatefile)
PROJECT_NAME="${project_name}"
AWS_REGION="${aws_region}"
DOMAIN_NAME="${domain_name}"

# Logs d'installation
 
exec > >(tee /var/log/user-data.log) 2>&1
echo ">>> Début de l'installation - $(date)"

# Mise à jour du système

echo ">>> Mise à jour du système..."
apt-get update -y
apt-get upgrade -y

# Installation des dépendances

echo ">>> Installation des dépendances..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    net-tools \
    jq \
    unzip \
    awscli

# Installation de K3s (sans Traefik ni ServiceLB)

echo ">>> Installation de K3s..."
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --disable servicelb

# Attendre que K3s soit prêt
echo ">>> Attente du démarrage de K3s..."
sleep 30
kubectl wait --for=condition=Ready nodes --all --timeout=120s


# Configuration kubectl pour l'utilisateur ubuntu

echo ">>> Configuration kubectl pour l'utilisateur ubuntu..."
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Variable KUBECONFIG pour la suite du script
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Alias kubectl
echo "alias k='kubectl'" >> /home/ubuntu/.bashrc
echo "export KUBECONFIG=/home/ubuntu/.kube/config" >> /home/ubuntu/.bashrc

# Installation de Helm

echo ">>> Installation de Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Installation de NGINX Ingress Controller

echo ">>> Installation de NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.hostPort.enabled=true \
    --set controller.service.type=ClusterIP

# Attendre NGINX Ingress
echo ">>> Attente du démarrage de NGINX Ingress..."
sleep 30

# Fin de l'installation

echo ">>> Installation terminée pour $PROJECT_NAME - $(date)"
echo ">>> Composants installés :"
echo "    - K3s (Kubernetes)"
echo "    - NGINX Ingress Controller"
echo ">>> Connexion via SSM :"
echo "    aws ssm start-session --target <INSTANCE_ID> --region $AWS_REGION"