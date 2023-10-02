<!-- BEGIN_TF_DOCS -->
# Elestio Keycloak Cluster Terraform module

## Benefits of a Keycloak cluster

A Keycloak cluster can handle more users without slowing down or crashing, and provides fault tolerance to ensure that the system remains operational.
It also allows for easy scalability to meet changing demands without replacing the entire system.

## Module requirements:

- 1 Elestio account https://dash.elest.io/signup
- 1 API key https://dash.elest.io/account/security
- 1 Database to store the data
- 1 SSH public/private key (see how to create one [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys))

## Module usage

This is a minimal example of how to use the module:

```hcl
module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id    = "xxxxxx"
  keycloak_pass = "xxxxxx"

  database        = "postgres"
  database_host   = "xxxxxx"
  database_port   = "5432"
  database_name   = "xxxxxx"
  database_schema = "public"
  database_user   = "xxxxxx"
  database_pass   = "xxxxxx"

  configuration_ssh_key = {
    username    = "something"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }

  nodes = [
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
}
```

Keep your keycloak password safe, you will need it to access the admin panel.

If you want to know more about node configuration, check the keycloak service documentation [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak).

If you want to choose your own provider, datacenter or server type, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types).

If you want to generated a valid SSH Key, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys).

If you add more nodes, you may attains the resources limit of your account, please visit your account [quota page](https://dash.elest.io/account/add-quota).

## Quick configuration

The following example will create a Keycloak cluster with 2 nodes, a database and a load balancer.

You may need to adjust the configuration to fit your needs.

Create a `main.tf` file at the root of your project, and fill it with your Elestio credentials:

```hcl
terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = "xxxx@xxxx.xxx"
  api_token = "xxxxxxxxxxxxx"
}

resource "elestio_project" "project" {
  name = "Keycloak Cluster"
}
```

Keycloak requires a database to store its data. To create one, add the following code to the file:

```hcl
resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  provider_name = "scaleway"
  datacenter    = "fr-par-1"
  server_type   = "SMALL-2C-2G"
}
```

Now you can use the module to create keycloak nodes:

```hcl
module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id       = elestio_project.project.id
  keycloak_version = null # null means latest version
  keycloak_pass    = "xxxxxxxxxxxxx"

  database        = "postgres"
  database_host   = elestio_postgresql.database.cname
  database_port   = elestio_postgresql.database.database_admin.port
  database_name   = "postgres"
  database_schema = "public"
  database_user   = elestio_postgresql.database.database_admin.user
  database_pass   = elestio_postgresql.database.database_admin.password

  configuration_ssh_key = {
    username    = "terraform"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }

  nodes = [
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
}
```

Each node is exposed on a different CNAME and IP address. You can add a load balancer to distribute the traffic between the nodes:

```hcl
resource "elestio_load_balancer" "load_balancer" {
  project_id    = elestio_project.project.id
  provider_name = "scaleway"
  datacenter    = "fr-par-1"
  server_type   = "SMALL-2C-2G"
  config = {
    target_services = [for node in module.cluster.nodes : node.id]
    forward_rules = [
      {
        port            = "443"
        protocol        = "HTTPS"
        target_port     = "443"
        target_protocol = "HTTPS"
      },
    ]
  }
}
```

Finally, let's add some outputs to retrieve useful information:

```hcl
output "nodes_admins" {
  value     = { for node in module.cluster.nodes : node.server_name => node.admin }
  sensitive = true
}

output "load_balancer_cname" {
  value = elestio_load_balancer.load_balancer.cname
}
```

You can now run `terraform init` and `terraform apply` to create your Keycloak cluster.
After a few minutes, the cluster will be ready to use.
You can access your outputs with `terraform output`:

```bash
$ terraform output nodes_admins
$ terraform output load_balancer_cname
```

If you want to update some parameters, you can edit the `main.tf` file and run `terraform apply` again.
Terraform will automatically update the cluster to match the new configuration.
Please note that changing the node count requires to change the .env of existing nodes. This is done automatically by the module.

## Ready-to-deploy example

We created a ready-to-deploy example which creates the same infrastructure as the previous example.
You can find it [here](https://github.com/elestio-examples/terraform-elestio-keycloak-cluster/tree/main/examples/get_started).
Follow the instructions to deploy the example.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_configuration_ssh_key"></a> [configuration\_ssh\_key](#input\_configuration\_ssh\_key) | After the nodes are created, Terraform must connect to apply some custom configuration.<br>This configuration is done using SSH from your local machine.<br>The Public Key will be added to the nodes and the Private Key will be used by your local machine to connect to the nodes.<br><br>Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys). Example:<pre>configuration_ssh_key = {<br>  username = "admin"<br>  public_key = chomp(file("\~/.ssh/id_rsa.pub"))<br>  private_key = file("\~/.ssh/id_rsa")<br>}</pre> | <pre>object({<br>    username    = string<br>    public_key  = string<br>    private_key = string<br>  })</pre> | n/a | yes |
| <a name="input_database"></a> [database](#input\_database) | Allowed values are `postgres`, `cockroach`, `mariadb`, `mysql`, `oracle`, or `mssql`. | `string` | `"postgres"` | no |
| <a name="input_database_host"></a> [database\_host](#input\_database\_host) | n/a | `string` | n/a | yes |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | n/a | `string` | `"postgres"` | no |
| <a name="input_database_pass"></a> [database\_pass](#input\_database\_pass) | n/a | `string` | n/a | yes |
| <a name="input_database_port"></a> [database\_port](#input\_database\_port) | n/a | `string` | `"5432"` | no |
| <a name="input_database_schema"></a> [database\_schema](#input\_database\_schema) | n/a | `string` | `"public"` | no |
| <a name="input_database_user"></a> [database\_user](#input\_database\_user) | n/a | `string` | n/a | yes |
| <a name="input_keycloak_pass"></a> [keycloak\_pass](#input\_keycloak\_pass) | The password can only contain alphanumeric characters or hyphens `-`.<br>Require at least 10 characters, one uppercase letter, one lowercase letter and one number.<br>Example: `qfeE42snU-bt0y-1KwbwZDq` DO NOT USE **THIS** EXAMPLE PASSWORD. | `string` | n/a | yes |
| <a name="input_keycloak_version"></a> [keycloak\_version](#input\_keycloak\_version) | The cluster nodes must share the same keycloak version.<br>Leave empty or set to `null` to use the Elestio recommended version. | `string` | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Each element of this list will create an Elestio Keycloak Resource in your cluster.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio Keycloak Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak). | <pre>list(<br>    object({<br>      server_name                                       = string<br>      provider_name                                     = string<br>      datacenter                                        = string<br>      server_type                                       = string<br>      admin_email                                       = optional(string)<br>      alerts_enabled                                    = optional(bool)<br>      app_auto_update_enabled                           = optional(bool)<br>      backups_enabled                                   = optional(bool)<br>      custom_domain_names                               = optional(set(string))<br>      firewall_enabled                                  = optional(bool)<br>      keep_backups_on_delete_enabled                    = optional(bool)<br>      remote_backups_enabled                            = optional(bool)<br>      support_level                                     = optional(string)<br>      system_auto_updates_security_patches_only_enabled = optional(bool)<br>      ssh_public_keys = optional(list(<br>        object({<br>          username = string<br>          key_data = string<br>        })<br>      ), [])<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
## Modules

No modules.
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nodes"></a> [nodes](#output\_nodes) | This is the created nodes full information |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | = 0.12.0 |
| <a name="provider_null"></a> [null](#provider\_null) | = 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | = 0.12.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | = 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/0.12.0/docs/resources/keycloak) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/3.2.0/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
