<!-- BEGIN_TF_DOCS -->
# Elestio Keycloak Cluster Terraform module

## Benefits of a Keycloak cluster

A Keycloak cluster can handle more users without slowing down or crashing, and provides fault tolerance to ensure that the system remains operational.
It also allows for easy scalability to meet changing demands without replacing the entire system.



## Usage

```hcl
module "keycloak_cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id = "1234"
  postgresql = null
  # If you want to use an existing PostgreSQL database, you can specify the configuration here:
  # postgresql = {
  #   host     = "my-postgresql-host.elest.io"
  #   port     = "5432"
  #   database = "keycloak"
  #   schema   = "public"
  #   username = "admin"
  #   password = var.postgresql_password
  # }
  keycloak_admin_password = var.keycloak_password
  ssh_key = {
    key_name    = "admin"
    public_key  = file("~/.ssh/id_rsa.pub")
    private_key = file("~/.ssh/id_rsa")
  }
  nodes = [
    {
      server_name   = "keycloak-germany"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
      admin_email   = "admin-germany@email.com"
    },
    {
      server_name   = "keycloak-finlande"
      provider_name = "hetzner"
      datacenter    = "hel1"
      server_type   = "SMALL-1C-2G"
      admin_email   = "admin-finlande@email.com"
    },
    # You can add more nodes here, but you need to have enough resources quota
    # You can see and udpdate your resources quota on https://dash.elest.io/account/add-quota
  ]
}

output "keycloak_admin" {
  value     = module.keycloak_cluster.keycloak_admin
  sensitive = true
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
| <a name="input_keycloak_admin_password"></a> [keycloak\_admin\_password](#input\_keycloak\_admin\_password) | Password of the adminUser created when keycloak starts.<br>The password can only contain alphanumeric characters or hyphens `-`.<br>Require at least 10 characters, one uppercase letter, one lowercase letter and one number. | `string` | n/a | yes |
| <a name="input_keycloak_version"></a> [keycloak\_version](#input\_keycloak\_version) | Keycloak version to use.<br>Leave empty or set to `null` to use the Elestio recommended version.<br>More information about the `version` can be found in the Elestio [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#version). | `string` | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | - `server_name`: Each resource must have a unique name within the project.<br><br>- `provider_name`, `datacenter`, `server_type`: [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/3_providers_datacenters_server_types).<br><br>- `support_level`: `level1`, `level2` or `level3` [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#support_level).<br><br>- `admin_email`: Email address of the administrator that will receive information about the node.<br><br>- `ssh_keys`: List of SSH keys that will be added to the node. [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#ssh_keys). | <pre>list(<br>    object({<br>      server_name   = string<br>      provider_name = string<br>      datacenter    = string<br>      server_type   = string<br>      support_level = optional(string, "level1")<br>      admin_email   = optional(string)<br>      ssh_keys = optional(list(<br>        object({<br>          key_name   = string<br>          public_key = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_postgresql"></a> [postgresql](#input\_postgresql) | PostgreSQL database configuration.<br>If null or not set, the module will create a new PostgreSQL database using the first node configuration (provider, datacenter, server\_type).<br>If you already have a PostgreSQL database, you can provide its configuration here. | <pre>object({<br>    host     = string<br>    port     = optional(string, "5432")<br>    database = string<br>    schema   = optional(string, "public")<br>    username = string<br>    password = string<br>  })</pre> | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the project that will contain the cluster.<br>More information about the `project_id` can be found in the Elestio [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#project_id). | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | This module requires Terraform to connect to the nodes to configure them.<br>This SSH key will be added to all nodes configuration. | <pre>object({<br>    key_name    = string<br>    public_key  = string<br>    private_key = string<br>  })</pre> | n/a | yes |
## Modules

No modules.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_keycloak_admin"></a> [keycloak\_admin](#output\_keycloak\_admin) | The URL and secrets to connectg to Keycloak Admin on each nodes |
| <a name="output_keycloak_nodes"></a> [keycloak\_nodes](#output\_keycloak\_nodes) | List of nodes of the Keycloak cluster |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | >= 0.10.2 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | >= 0.10.2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak) | resource |
| [elestio_postgresql.database](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/postgresql) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
