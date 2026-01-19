# Informations VPC


output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID du subnet public"
  value       = aws_subnet.public.id
}

# Informations EC2

output "ec2_spot_request_id" {
  description = "ID de la requête Spot"
  value       = aws_spot_instance_request.ec2.id
}

output "ec2_instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_spot_instance_request.ec2.spot_instance_id
}

output "ec2_public_ip" {
  description = "IP publique (Elastic IP) de l'instance ec2"
  value       = aws_eip.ec2.public_ip
}

# Commandes de connexion

output "ssm_connection_command" {
  description = "Commande pour se connecter via SSM"
  value       = "aws ssm start-session --target ${aws_spot_instance_request.ec2.spot_instance_id} --region ${var.aws_region}"
}