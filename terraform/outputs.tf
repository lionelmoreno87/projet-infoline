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

# API Gateway

output "api_gateway_url" {
  description = "URL de l'API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_name" {
  description = "Nom de la fonction Lambda"
  value       = aws_lambda_function.login.function_name
}

# Informations S3

output "s3_bucket_name" {
  description = "Nom du bucket S3 pour les backups"
  value       = aws_s3_bucket.backups.id
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3"
  value       = aws_s3_bucket.backups.arn
}

