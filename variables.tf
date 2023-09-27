variable "project_id" {
  type = string
}

variable "keycloak_version" {
  type        = string
  nullable    = true
  default     = null
  description = <<-EOF
    The cluster nodes must share the same keycloak version.
    Leave empty or set to `null` to use the Elestio recommended version.
  EOF
}

variable "keycloak_admin_password" {
  type        = string
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

variable "configuration_ssh_key" {
  type = object({
    username    = string
    public_key  = string
    private_key = string
  })
  nullable    = false
  sensitive   = true
  description = <<-EOF
    After the nodes are created, Terraform must connect to apply some custom configuration.
    This configuration is done using SSH from your local machine.
    The Public Key will be added to the nodes and the Private Key will be used by your local machine to connect to the nodes.

    Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys).
    Example:
    ```
    configuration_ssh_key = {
      username = "admin"
      public_key = chomp(file("~/.ssh/id_rsa.pub"))
      private_key = file("~/.ssh/id_rsa")
    }
    ```
  EOF
}

variable "nodes" {
  type = list(
    object({
      server_name                                       = string
      provider_name                                     = string
      datacenter                                        = string
      server_type                                       = string
      admin_email                                       = optional(string)
      alerts_enabled                                    = optional(bool)
      app_auto_update_enabled                           = optional(bool)
      backups_enabled                                   = optional(bool)
      custom_domain_names                               = optional(set(string))
      firewall_enabled                                  = optional(bool)
      keep_backups_on_delete_enabled                    = optional(bool)
      remote_backups_enabled                            = optional(bool)
      support_level                                     = optional(string)
      system_auto_updates_security_patches_only_enabled = optional(bool)
      ssh_public_keys = optional(list(
        object({
          username = string
          key_data = string
        })
      ), [])
    })
  )
  default     = []
  description = <<-EOF
    Each element of this list will create an Elestio Keycloak Resource in your cluster.
    Read the following documentation to understand what each attribute does, plus the default values: [Elestio Keycloak Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak).
  EOF
  validation {
    error_message = "You must provide at least one node."
    condition     = length(var.nodes) > 0
  }
  validation {
    error_message = "You must provide a unique server_name for each node."
    condition     = length(var.nodes) == length(toset([for node in var.nodes : node.server_name]))
  }
}

variable "postgresql" {
  type = object({
    create = optional(object({
      provider_name                                     = string
      datacenter                                        = string
      server_type                                       = string
      server_name                                       = optional(string)
      version                                           = optional(string)
      database_name                                     = optional(string, "keycloak")
      default_password                                  = optional(string)
      admin_email                                       = optional(string)
      alerts_enabled                                    = optional(bool)
      app_auto_update_enabled                           = optional(bool)
      backups_enabled                                   = optional(bool)
      firewall_enabled                                  = optional(bool)
      keep_backups_on_delete_enabled                    = optional(bool)
      remote_backups_enabled                            = optional(bool)
      support_level                                     = optional(string)
      system_auto_updates_security_patches_only_enabled = optional(bool)
      ssh_public_keys = optional(list(
        object({
          username = string
          key_data = string
        })
      ), [])
    }))
    use = optional(object({
      host          = string
      port          = optional(string, "5432")
      database_name = string
      schema        = optional(string, "public")
      username      = string
      password      = string
    }))
  })
  description = <<-EOF
    Keycloak requires a PostgreSQL database to store its data.
    You can create one using the `create` attribute.
    If you already have one, you can fill the `use` attribute with its configuration.
    Read the following documentation to understand what each attribute does, plus the default values: [Elestio PostgreSQL Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/postgresql).
  EOF
  validation {
    error_message = "You must provide either the create or use attribute."
    condition = anytrue([
      var.postgresql.create != null && var.postgresql.use == null,
      var.postgresql.create == null && var.postgresql.use != null,
    ])
  }
}

variable "load_balancer" {
  type = object({
    provider_name = string
    datacenter    = string
    server_type   = string
    server_name   = optional(string)
    config = optional(object({
      access_logs_enabled      = optional(bool)
      ip_rate_limit_enabled    = optional(bool)
      ip_rate_limit_per_second = optional(number)
      output_cache_in_seconds  = optional(number)
      output_headers = optional(set(object({
        key   = string
        value = string
      })))
      proxy_protocol_enabled  = optional(bool)
      remove_response_headers = optional(set(string))
      sticky_sessions_enabled = optional(bool)
    }))
  })
  nullable    = true
  default     = null
  description = <<-EOF
    It will create a load balancer in front of the cluster.
    Read the following documentation to understand what each attribute does, plus the default values: [Elestio Load Balancer Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/load_balancer).
  EOF
}
