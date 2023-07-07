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
      support_level = string
      admin_email   = string
      ssh_keys = list(
        object({
          key_name   = string
          public_key = string
        })
      )
    })
  )
  default     = []
  description = <<-EOF
    - `server_name`: Each resource must have a unique name within the project.

    - `provider_name`, `datacenter`, `server_type`: [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/3_providers_datacenters_server_types).

    - `support_level`: `level1`, `level2` or `level3` [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#support_level).

    - `admin_email`: Email address of the administrator that will receive information about the node.
  EOF

  validation {
    condition     = length(var.nodes) > 0
    error_message = "You must provide in at least one node configuration."
  }
}

variable "global_ssh_key" {
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

variable "postgresql_host" {
  type        = string
  nullable    = false
  description = "PostgreSQL database hostname"
}

variable "postgresql_port" {
  type        = string
  default     = "5432"
  description = "PostgreSQL database port"
}

variable "postgresql_database" {
  type        = string
  nullable    = false
  description = "PostgreSQL database name where Keycloak will store its data"
}

variable "postgresql_schema" {
  type        = string
  default     = "public"
  description = "PostgreSQL database schema where Keycloak will store its data"
}

variable "postgresql_username" {
  type        = string
  nullable    = false
  description = "PostgreSQL database username"
}

variable "postgresql_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "PostgreSQL database password"
}

variable "keycloak_admin_user" {
  type        = string
  nullable    = false
  description = "Name of the adminUser created when keycloak starts."
}

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
    condition     = length(var.keycloak_password) > 10
    error_message = "The password must be longer than 10 characters."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.keycloak_password))
    error_message = "The password can only contain alphanumeric characters or hyphens `-`."
  }
  validation {
    condition     = can(regex("^(?=.*[A-Z]).*$", var.keycloak_password))
    error_message = "The password must contain at least one uppercase letter."
  }
  validation {
    condition     = can(regex("^(?=.*[a-z]).*$", var.keycloak_password))
    error_message = "The password must contain at least one lowercase letter."
  }
  validation {
    condition     = can(regex("^(?=.*[0-9]).*$", var.keycloak_password))
    error_message = "The password must contain at least one number."
  }
}
