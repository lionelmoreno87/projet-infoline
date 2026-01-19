# Security Group 

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group pour instance K3s InfoLine (SSM, pas de SSH)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Règles Ingress (trafic entrant)

# HTTP - Redirection vers HTTPS (port 80)
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTP (redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ingress_cidr

  tags = {
    Name = "${var.project_name}-http"
  }
}

# HTTPS - Trafic web sécurisé via NGINX Ingress (port 443)
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTPS (NGINX Ingress + cert-manager)"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ingress_cidr

  tags = {
    Name = "${var.project_name}-https"
  }
}

# Règle Egress (trafic sortant)

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-all-outbound"
  }
}

# API Kubernetes
resource "aws_vpc_security_group_ingress_rule" "ec2_api" {
  count             = var.enable_ec2_api_access ? 1 : 0
  security_group_id = aws_security_group.ec2.id
  description       = "Kubernetes API (kubectl distant)"
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ec2_api_cidr

  tags = {
    Name = "${var.project_name}-ec2-api"
  }
}