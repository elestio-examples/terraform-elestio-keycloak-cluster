<!-- BEGIN_TF_DOCS -->
# Elestio Keycloak Cluster Terraform module

## Benefits of a Keycloak cluster

A Keycloak cluster can handle more users without slowing down or crashing, and provides fault tolerance to ensure that the system remains operational.
It also allows for easy scalability to meet changing demands without replacing the entire system.



## Usage

```hcl
module "keycloak_cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id              = "1234"
  keycloak_version        = null # if null the latest version will be installed
  keycloak_admin_password = var.keycloak_password
  configuration_ssh_key = {
    # https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys
    username    = "admin"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }
  nodes = [
    # You can add more nodes here, but you need to have enough resources quota
    # You can see and udpdate your resources quota on https://dash.elest.io/account/add-quota
    {
      server_name   = "keycloak-1"
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      server_type   = "SMALL-2C-2G"
    },
    {
      server_name   = "keycloak-2"
      provider_name = "scaleway"
      datacenter    = "fr-par-2"
      server_type   = "SMALL-2C-2G"
    },

  ]
  postgresql = {
    create = {
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      server_type   = "SMALL-2C-2G"
    }
  }
  load_balancer = {
    provider_name = "scaleway"
    datacenter    = "fr-par-1"
    server_type   = "SMALL-2C-2G"
  }
}

# The outputs extract module information. Use `terraform output` after cluster creation to retrieve it.
output "nodes" {
  description = "this is the created nodes full information"
  value       = module.cluster.nodes
  sensitive   = true
}
output "node_admins" {
  description = "the URL and secrets to connect to Keycloak Admin on each nodes"
  value       = module.cluster.node_admins
  sensitive   = true
}
output "database" {
  description = "this is the created database information"
  value       = module.cluster.database
  sensitive   = true
}
output "load_balancer" {
  description = "this is the created load balancer information"
  value       = module.cluster.load_balancer
  sensitive   = true
}
```

## What the module does

1. If you don't provide a **Postgres** database config, it creates a new one for you.

2. It configures the Keycloak nodes to use the database and to be clustered together.

3. If you change the number of nodes and re-apply, it will automatically reconfigure the cluster for you.

## Examples

- [Get started](https://github.com/elestio-examples/terraform-elestio-keycloak-cluster/tree/main/examples/get_started) - Ready-to-deploy example which creates a Keycloak Cluster and a Load Balancer.

## How to access the Keycloak nodes

Use `terraform output keycloak_admin` command to output keycloak admin secrets:

```bash
# keycloak_admin
{
  "keycloak-finlande" = {
    "password" = "*****"
    "url" = "https://keycloak-finlande-u525.vm.elestio.app:443/"
    "user" = "root"
  }
  "keycloak-germany" = {
    "password" = "*****"
    "url" = "https://keycloak-germany-u525.vm.elestio.app:443/"
    "user" = "root"
  }
}
```

Each node is exposed on a different CNAME and IP address.
If you need to expose the Keycloak nodes on the same IP address, you will need to create separatly a load balancer.
Check the [ready-to-deploy example](https://github.com/elestio-examples/terraform-elestio-keycloak-cluster/tree/main/examples/get_started) for a full usage example.

## Scale the nodes

To adjust the cluster size:

- Adding nodes: Run `terraform apply` after adding a new node, and it will be seamlessly integrated into the cluster.
- Removing nodes: The excess nodes will cleanly leave the cluster on the next `terraform apply`.

Please note that changing the node count requires to change the .env of existing nodes. This is done automatically by the module.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configuration_ssh_key"></a> [configuration\_ssh\_key](#input\_configuration\_ssh\_key) | After the nodes are created, Terraform must connect to apply some custom configuration.<br>This configuration is done using SSH from your local machine.<br>The Public Key will be added to the nodes and the Private Key will be used by your local machine to connect to the nodes.<br><br>Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys).<br>Example:<pre>configuration_ssh_key = {<br>  username = "admin"<br>  public_key = chomp(file("~/.ssh/id_rsa.pub"))<br>  private_key = file("~/.ssh/id_rsa")<br>}</pre> | <pre>object({<br>    username    = string<br>    public_key  = string<br>    private_key = string<br>  })</pre> | n/a | yes |
| <a name="input_keycloak_admin_password"></a> [keycloak\_admin\_password](#input\_keycloak\_admin\_password) | Password of the adminUser created when keycloak starts.<br>The password can only contain alphanumeric characters or hyphens `-`.<br>Require at least 10 characters, one uppercase letter, one lowercase letter and one number. | `string` | n/a | yes |
| <a name="input_keycloak_version"></a> [keycloak\_version](#input\_keycloak\_version) | The cluster nodes must share the same keycloak version.<br>Leave empty or set to `null` to use the Elestio recommended version. | `string` | `null` | no |
| <a name="input_load_balancer"></a> [load\_balancer](#input\_load\_balancer) | It will create a load balancer in front of the cluster.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio Load Balancer Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/load_balancer). | <pre>object({<br>    provider_name = string<br>    datacenter    = string<br>    server_type   = string<br>    server_name   = optional(string)<br>    config = optional(object({<br>      access_logs_enabled      = optional(bool)<br>      ip_rate_limit_enabled    = optional(bool)<br>      ip_rate_limit_per_second = optional(number)<br>      output_cache_in_seconds  = optional(number)<br>      output_headers = optional(set(object({<br>        key   = string<br>        value = string<br>      })))<br>      proxy_protocol_enabled  = optional(bool)<br>      remove_response_headers = optional(set(string))<br>      sticky_sessions_enabled = optional(bool)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Each element of this list will create an Elestio Keycloak Resource in your cluster.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio Keycloak Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak). | <pre>list(<br>    object({<br>      server_name                                       = string<br>      provider_name                                     = string<br>      datacenter                                        = string<br>      server_type                                       = string<br>      admin_email                                       = optional(string)<br>      alerts_enabled                                    = optional(bool)<br>      app_auto_update_enabled                           = optional(bool)<br>      backups_enabled                                   = optional(bool)<br>      custom_domain_names                               = optional(set(string))<br>      firewall_enabled                                  = optional(bool)<br>      keep_backups_on_delete_enabled                    = optional(bool)<br>      remote_backups_enabled                            = optional(bool)<br>      support_level                                     = optional(string)<br>      system_auto_updates_security_patches_only_enabled = optional(bool)<br>      ssh_public_keys = optional(list(<br>        object({<br>          username = string<br>          key_data = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_postgresql"></a> [postgresql](#input\_postgresql) | Keycloak requires a PostgreSQL database to store its data.<br>You can create one using the `create` attribute.<br>If you already have one, you can fill the `use` attribute with its configuration.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio PostgreSQL Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/postgresql). | <pre>object({<br>    create = optional(object({<br>      provider_name                                     = string<br>      datacenter                                        = string<br>      server_type                                       = string<br>      server_name                                       = optional(string)<br>      version                                           = optional(string)<br>      database_name                                     = optional(string, "keycloak")<br>      default_password                                  = optional(string)<br>      admin_email                                       = optional(string)<br>      alerts_enabled                                    = optional(bool)<br>      app_auto_update_enabled                           = optional(bool)<br>      backups_enabled                                   = optional(bool)<br>      firewall_enabled                                  = optional(bool)<br>      keep_backups_on_delete_enabled                    = optional(bool)<br>      remote_backups_enabled                            = optional(bool)<br>      support_level                                     = optional(string)<br>      system_auto_updates_security_patches_only_enabled = optional(bool)<br>      ssh_public_keys = optional(list(<br>        object({<br>          username = string<br>          key_data = string<br>        })<br>      ), [])<br>    }))<br>    use = optional(object({<br>      host          = string<br>      port          = optional(string, "5432")<br>      database_name = string<br>      schema        = optional(string, "public")<br>      username      = string<br>      password      = string<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
## Modules

No modules.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database"></a> [database](#output\_database) | This is the created database information |
| <a name="output_load_balancer"></a> [load\_balancer](#output\_load\_balancer) | This is the created load balancer information |
| <a name="output_node_admins"></a> [node\_admins](#output\_node\_admins) | The URL and secrets to connect to Keycloak Admin on each nodes |
| <a name="output_nodes"></a> [nodes](#output\_nodes) | This is the created nodes full information |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | >= 0.12.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | >= 0.12.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak) | resource |
| [elestio_load_balancer.load_balancer](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/load_balancer) | resource |
| [elestio_postgresql.database](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/postgresql) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
