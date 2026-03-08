# -----------------------------------------------------------------------------
# Techbleat DevOps - Terraform Outputs
# -----------------------------------------------------------------------------

output "server_public_ip" {
  description = "Public IP address of the Techbleat server"
  value       = aws_instance.techbleat_server.public_ip
}

output "server_public_dns" {
  description = "Public DNS name of the Techbleat server"
  value       = aws_instance.techbleat_server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.techbleat_server.public_ip}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = aws_db_instance.techbleat_db.endpoint
}

output "database_url" {
  description = "PostgreSQL connection string for the app"
  value       = "postgresql+psycopg://${var.db_username}:${var.db_password}@${aws_db_instance.techbleat_db.address}:5432/${var.db_name}?sslmode=require"
  sensitive   = true
}

output "domain_name" {
  description = "App domain (for Jenkins)"
  value       = var.domain_name
}

output "route53_nameservers" {
  description = "Set these nameservers at your domain registrar (one-time). Skip if domain registered in Route53."
  value       = local.create_zone ? aws_route53_zone.main[0].name_servers : []
}
