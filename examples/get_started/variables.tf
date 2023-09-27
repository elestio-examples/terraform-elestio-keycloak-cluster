variable "elestio_email" {
  type = string
}

variable "elestio_api_token" {
  type      = string
  sensitive = true
}

variable "keycloak_password" {
  type      = string
  sensitive = true
}
