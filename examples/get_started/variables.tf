variable "elestio_email" {
  type     = string
  nullable = false
}

variable "elestio_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "keycloak_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = <<-EOF
    Password of the admin user created when keycloak starts.
    This password will be used to connect to the keycloak admin console.
  EOF
}

variable "ssh_key_name" {
  type        = string
  nullable    = false
  description = "Name of the SSH key"
}

variable "ssh_public_key" {
  type        = string
  nullable    = false
  description = "Public key of the SSH key"
}

variable "ssh_private_key" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "Private key of the SSH key"
}
