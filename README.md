<!-- BEGIN_TF_DOCS -->
# Elestio Keycloak Cluster Terraform module



## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_keycloak_admin_password"></a> [keycloak\_admin\_password](#input\_keycloak\_admin\_password) | Password of the adminUser created when keycloak starts.<br>The password can only contain alphanumeric characters or hyphens `-`.<br>Require at least 10 characters, one uppercase letter, one lowercase letter and one number. | `string` | n/a | yes |
| <a name="input_keycloak_version"></a> [keycloak\_version](#input\_keycloak\_version) | Keycloak version to use.<br>Leave empty or set to `null` to use the Elestio recommended version.<br>More information about the `version` can be found in the Elestio [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#version). | `string` | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | - `server_name`: Each resource must have a unique name within the project.<br><br>- `provider_name`, `datacenter`, `server_type`: [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/3_providers_datacenters_server_types).<br><br>- `support_level`: `level1`, `level2` or `level3` [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#support_level).<br><br>- `admin_email`: Email address of the administrator that will receive information about the node.<br><br>- `ssh_keys`: List of SSH keys that will be added to the node. [documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak#ssh_keys). | <pre>list(<br>    object({<br>      server_name   = string<br>      provider_name = string<br>      datacenter    = string<br>      server_type   = string<br>      support_level = optional(string, "level1")<br>      admin_email   = string<br>      ssh_keys = optional(list(<br>        object({<br>          key_name   = string<br>          public_key = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
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
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | >= 0.9.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | >= 0.9.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak) | resource |
| [elestio_postgresql.database](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/postgresql) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
