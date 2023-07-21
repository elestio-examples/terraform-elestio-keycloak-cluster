variable "project_id" {
  type        = string
  nullable    = false
  description = <<-EOF
    ID of the project that will contain the cluster.
    More information about the `project_id` can be found in the Elestio [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#project_id).
  EOF
}

variable "keycloak_version" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOF
    Keycloak version to use.
    Leave empty or set to `null` to use the Elestio recommended version.
    More information about the `version` can be found in the Elestio [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#version).
  EOF
}

variable "nodes" {
  type = list(
    object({
      server_name   = string
      provider_name = string
      datacenter    = string
      server_type   = string
      support_level = optional(string, "level1")
      admin_email   = optional(string)
      ssh_keys = optional(list(
        object({
          key_name   = string
          public_key = string
        })
      ), [])
    })
  )
  default     = []
  description = <<-EOF
    - `server_name`: Each resource must have a unique name within the project.

    - `provider_name`, `datacenter`, `server_type`: [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/3_providers_datacenters_server_types).

    - `support_level`: `level1`, `level2` or `level3` [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#support_level).

    - `admin_email`: Email address of the administrator that will receive information about the node.

    - `ssh_keys`: List of SSH keys that will be added to the node. [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#ssh_keys).
  EOF

  validation {
    condition     = length(var.nodes) > 0
    error_message = "You must provide in at least one node configuration."
  }
}

variable "ssh_key" {
  type = object({
    key_name    = string
    public_key  = string
    private_key = string
  })
  nullable    = false
  sensitive   = true
  description = <<-EOF
    This module requires Terraform to connect to the nodes to configure them.
    This SSH key will be added to all nodes configuration.
  EOF
}

variable "postgresql" {
  type = object({
    host     = string
    port     = optional(string, "5432")
    database = string
    schema   = optional(string, "public")
    username = string
    password = string
  })
  default     = null
  sensitive   = true
  description = <<-EOF
    PostgreSQL database configuration.
    If null or not set, the module will create a new PostgreSQL database using the first node configuration (provider, datacenter, server_type).
    If you already have a PostgreSQL database, you can provide its configuration here.
  EOF
}

# TODO: handle custom admin user (update /opt/proxy_443.secret)
# variable "keycloak_admin_user" {
#   type        = string
#   default     = "root"
#   description = "Name of the adminUser created when keycloak starts."
# }

variable "keycloak_admin_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = <<-EOF
    Password of the adminUser created when keycloak starts.
    The password can only contain alphanumeric characters or hyphens `-`.
    Require at least 10 characters, one uppercase letter, one lowercase letter and one number.
  EOF
  validation {
    condition     = length(var.keycloak_admin_password) >= 10
    error_message = "The password must be at least 10 characters long."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.keycloak_admin_password))
    error_message = "The password can only contain alphanumeric characters or hyphens `-`."
  }
  validation {
    condition     = can(regex("[A-Z]", var.keycloak_admin_password))
    error_message = "The password must contain at least one uppercase letter."
  }
  validation {
    condition     = can(regex("[a-z]", var.keycloak_admin_password))
    error_message = "The password must contain at least one lowercase letter."
  }
  validation {
    condition     = can(regex("[0-9]", var.keycloak_admin_password))
    error_message = "The password must contain at least one number."
  }
}
