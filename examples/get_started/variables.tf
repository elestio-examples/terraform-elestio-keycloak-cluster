variable "elestio_email" {
  type     = string
  nullable = false
}

variable "elestio_api_token" {
  type      = string
  nullable  = false
  sensitive = true
}

# If you want to store your ssh key in string, uncomment the following lines:
# variable "ssh_key" {
#   type = object({
#     name        = string
#     public_key  = string
#     private_key = string
#   })
#   nullable  = false
#   sensitive = true
# }
