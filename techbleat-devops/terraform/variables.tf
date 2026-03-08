# -----------------------------------------------------------------------------
# Techbleat DevOps - Terraform Variables
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair for EC2 access"
  type        = string
  default     = "MasterClass2025"
}

# -----------------------------------------------------------------------------
# RDS / Database
# -----------------------------------------------------------------------------
variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "techbleat"
}

variable "db_password" {
  description = "PostgreSQL master password"
  type        = string
  default     = "Techbleat2026!"
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# -----------------------------------------------------------------------------
# DNS (optional - fully automated when domain_name set)
# -----------------------------------------------------------------------------
variable "domain_name" {
  description = "Full domain for the app (e.g. market.techbleat-stores.co.uk). Terraform creates hosted zone + A record. Set nameservers at your registrar from terraform output."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Existing Route53 zone ID. Leave empty to auto-create zone for domain (uses root of domain_name)."
  type        = string
  default     = ""
}
