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

output "ec2_instance_id" {
  description = "ID de l'instance k3s"
  value       = aws_instance.ec2.id
}

output "ec2_public_ip" {
  description = "IP publique de l'instance k3s"
  value       = aws_eip.ec2.public_ip
}

output "ssm_connection_command" {
  description = "Commande pour se connecter via SSM"
  value       = "aws ssm start-session --target ${aws_instance.ec2.id} --region ${var.aws_region}"
}
