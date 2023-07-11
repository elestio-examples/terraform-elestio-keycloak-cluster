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

locals {
  # Use locals if you key is in a file
  ssh_key = {
    key_name    = "admin"
    public_key  = file("~/.ssh/id_rsa.pub")
    private_key = file("~/.ssh/id_rsa")
  }
}

# Use variables if you want to pass the key as strings in secrets.tfvars
# variable "ssh_key" {
#   type = object({
#     key_name    = string
#     public_key  = string
#     private_key = string
#   })
#   nullable  = false
#   sensitive = true
# }
