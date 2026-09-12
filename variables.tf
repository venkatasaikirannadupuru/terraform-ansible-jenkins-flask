variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
}
