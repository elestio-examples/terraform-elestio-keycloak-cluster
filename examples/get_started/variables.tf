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
    Password of the adminUser created when keycloak starts.
    The password can only contain alphanumeric characters or hyphens `-`.
    Require at least 10 characters, one uppercase letter, one lowercase letter and one number.
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
