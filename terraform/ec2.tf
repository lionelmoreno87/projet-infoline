# Data Source - AMI Ubuntu

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance EC2 - K3s

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

user_data = templatefile("${path.module}/scripts/user-data.sh", {
  project_name = var.project_name
  aws_region   = var.aws_region
  domain_name  = var.domain_name    
})

  tags = {
    Name = "${var.project_name}-k3s"
  }
}

# Elastic IP

resource "aws_eip" "ec2" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-ec2-eip"
  }
}

# Association Elastic IP <-> Instance

resource "aws_eip_association" "ec2" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.ec2.id
}