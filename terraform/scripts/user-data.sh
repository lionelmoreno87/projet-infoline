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

# Pause pour Elastic IP
echo ">>> Attente de la stabilisation réseau (Elastic IP)..."
sleep 30

# Récupération de l'IP publique
echo ">>> Récupération de l'IP publique..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo ">>> IP publique détectée: $PUBLIC_IP"

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

# Installation de K3s
echo ">>> Installation de K3s avec TLS-SAN: $PUBLIC_IP..."
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --disable servicelb \
    --tls-san "$PUBLIC_IP"

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
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo update

KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.hostPort.enabled=true \
    --set controller.service.type=ClusterIP

# Attendre NGINX Ingress
echo ">>> Attente du démarrage de NGINX Ingress..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

# Installation de cert-manager
echo ">>> Installation de cert-manager..."
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo add jetstack https://charts.jetstack.io
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo update

KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

# Attendre que cert-manager soit prêt
echo ">>> Attente du démarrage de cert-manager..."
kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=120s

# Configuration Let's Encrypt
if [ -n "$DOMAIN_NAME" ]; then
echo ">>> Configuration ClusterIssuer Let's Encrypt pour $DOMAIN_NAME..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@$DOMAIN_NAME
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
fi

# Installation AWS EBS CSI Driver
echo ">>> Installation AWS EBS CSI Driver..."
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm repo update

KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
    --namespace kube-system \
    --set controller.serviceAccount.create=true \
    --set node.serviceAccount.create=true

# Créer la StorageClass gp3 par défaut
echo ">>> Création de la StorageClass ebs-gp3..."
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# Fin de l'installation
echo ">>> Installation terminée pour $PROJECT_NAME - $(date)"
echo ">>> IP publique: $PUBLIC_IP"
echo ">>> Composants installés :"
echo "    - K3s (Kubernetes) avec TLS-SAN $PUBLIC_IP"
echo "    - NGINX Ingress Controller"
echo "    - cert-manager + Let's Encrypt"
echo "    - AWS EBS CSI Driver"
echo ">>> Connexion via SSM :"
echo "    aws ssm start-session --target <INSTANCE_ID> --region $AWS_REGION"