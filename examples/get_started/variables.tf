variable "elestio_email" {
  type     = string
  nullable = false
}

variable "elestio_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "keycloak_admin_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = <<-EOF
    Password of the adminUser created when keycloak starts.
    This password will be used to connect to the keycloak admin console.
  EOF
}
