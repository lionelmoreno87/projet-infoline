#!/bin/bash

# Ce script s'exécute au premier démarrage de l'instance
# Installe : K3s, Helm, NGINX Ingress, cert-manager, ELK Stack

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
    --set crds.enabled=true

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

# ============================================
# Installation ELK Stack (Monitoring)
# ============================================

echo ">>> Installation de la stack ELK..."

# Créer le namespace monitoring
kubectl create namespace monitoring

# Déployer Elasticsearch
echo ">>> Déploiement d'Elasticsearch..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: elasticsearch-data
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  serviceName: elasticsearch
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
        - name: elasticsearch
          image: docker.elastic.co/elasticsearch/elasticsearch:7.17.18
          env:
            - name: discovery.type
              value: single-node
            - name: ES_JAVA_OPTS
              value: "-Xms512m -Xmx512m"
            - name: xpack.security.enabled
              value: "false"
          ports:
            - containerPort: 9200
              name: http
            - containerPort: 9300
              name: transport
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: elasticsearch-data
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  selector:
    app: elasticsearch
  ports:
    - port: 9200
      targetPort: 9200
      name: http
    - port: 9300
      targetPort: 9300
      name: transport
  clusterIP: None
EOF

# Attendre qu'Elasticsearch soit prêt
echo ">>> Attente du démarrage d'Elasticsearch..."
kubectl wait --namespace monitoring \
    --for=condition=ready pod \
    --selector=app=elasticsearch \
    --timeout=300s

# Déployer Kibana
echo ">>> Déploiement de Kibana..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
        - name: kibana
          image: docker.elastic.co/kibana/kibana:7.17.18
          env:
            - name: ELASTICSEARCH_HOSTS
              value: "http://elasticsearch:9200"
          ports:
            - containerPort: 5601
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "300m"
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: monitoring
spec:
  selector:
    app: kibana
  ports:
    - port: 5601
      targetPort: 5601
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  rules:
    - host: kibana.$PUBLIC_IP.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kibana
                port:
                  number: 5601
EOF

# Attendre que Kibana soit prêt
echo ">>> Attente du démarrage de Kibana..."
kubectl wait --namespace monitoring \
    --for=condition=ready pod \
    --selector=app=kibana \
    --timeout=300s

# Déployer Filebeat
echo ">>> Déploiement de Filebeat..."
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces", "nodes"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
  - kind: ServiceAccount
    name: filebeat
    namespace: monitoring
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: monitoring
data:
  filebeat.yml: |
    filebeat.autodiscover:
      providers:
        - type: kubernetes
          node: $${NODE_NAME}
          hints.enabled: true
          hints.default_config:
            type: container
            paths:
              - /var/log/containers/*$${data.kubernetes.container.id}.log
    output.elasticsearch:
      hosts: ["elasticsearch:9200"]
    setup.kibana:
      host: "kibana:5601"
    logging.level: info
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: filebeat
  template:
    metadata:
      labels:
        app: filebeat
    spec:
      serviceAccountName: filebeat
      containers:
        - name: filebeat
          image: docker.elastic.co/beats/filebeat:7.17.18
          args: ["-c", "/etc/filebeat.yml", "-e"]
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          securityContext:
            runAsUser: 0
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "128Mi"
              cpu: "100m"
          volumeMounts:
            - name: config
              mountPath: /etc/filebeat.yml
              subPath: filebeat.yml
              readOnly: true
            - name: varlog
              mountPath: /var/log
              readOnly: true
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
      volumes:
        - name: config
          configMap:
            name: filebeat-config
        - name: varlog
          hostPath:
            path: /var/log
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
EOF

echo ">>> Stack ELK déployée avec succès !"
echo ">>> Kibana accessible sur : http://kibana.$PUBLIC_IP.nip.io"

# Fin de l'installation
echo ">>> Installation terminée pour $PROJECT_NAME - $(date)"
echo ">>> IP publique: $PUBLIC_IP"
echo ">>> Composants installés :"
echo "    - K3s (Kubernetes) avec TLS-SAN $PUBLIC_IP"
echo "    - NGINX Ingress Controller"
echo "    - cert-manager + Let's Encrypt"
echo "    - AWS EBS CSI Driver"
echo "    - Elasticsearch 7.17.18"
echo "    - Kibana 7.17.18"
echo "    - Filebeat 7.17.18"
echo ">>> Accès Kibana : http://kibana.$PUBLIC_IP.nip.io"
echo ">>> Connexion via SSM :"
echo "    aws ssm start-session --target <INSTANCE_ID> --region $AWS_REGION"