<!-- BEGIN_TF_DOCS -->
# Elestio Keycloak Cluster Terraform module

## Benefits of a Keycloak cluster

A Keycloak cluster can handle more users without slowing down or crashing, and provides fault tolerance to ensure that the system remains operational.
It also allows for easy scalability to meet changing demands without replacing the entire system.



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
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      server_name   = "keycloak-2"
      provider_name = "hetzner"
      datacenter    = "nbg1"
      server_type   = "SMALL-1C-2G"
    },
  ]
}
```

Keep your keycloak password safe, you will need it to access the admin panel.

If you want to know more about node configuration, check the keycloak service documentation [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak).

If you want to choose your own provider, datacenter or server type, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types).

If you want to generated a valid SSH Key, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys).

If you add more nodes, you may attains the resources limit of your account, please visit your account [quota page](https://dash.elest.io/account/add-quota).

## Step-by-step

The following example will create a Keycloak cluster with 2 nodes, a database and a load balancer.
You may need to adjust the configuration to fit your needs.

### 1. Store your secrets

Some secrets are required to create the cluster.
For security reasons, we recommend to store them in a `.tfvars` file and add it to your `.gitignore` file.
Create a `terraform.tfvars` file:

```hcl
# terraform.tfvars
elestio_email     = "****" # Create an Elestio account https://dash.elest.io/signup
elestio_api_token = "****" # Generate an API token https://dash.elest.io/account/security
keycloak_pass     = "****" # Generated a keycloak password https://api.elest.io/api/auth/passwordgenerator
```

Terraform needs a ssh key to connect to the nodes and configure them.
If you don't have one, you can create it with the following command:

```bash
ssh-keygen -t rsa
```

Remember the path and name, we will need it later.

### 2. Write the configuration

Create a `main.tf` file:

```hcl
# main.tf

variable "elestio_email" {
  type = string
}

variable "elestio_api_token" {
  type      = string
  sensitive = true
}

variable "keycloak_pass" {
  type      = string
  sensitive = true
}

terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = var.elestio_email
  api_token = var.elestio_api_token
}

resource "elestio_project" "project" {
  name = "Keycloak Cluster"
}
```

Add a database:

```hcl
# ...main.tf

resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
}
```

-> If you want to choose your own provider, datacenter or server type, check the guide [here](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types).

Add the module:

```hcl
# ...main.tf

module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id       = elestio_project.project.id
  keycloak_version = null # null means latest version
  keycloak_pass    = var.keycloak_pass

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
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      server_name   = "keycloak-2"
      provider_name = "hetzner"
      datacenter    = "nbg1"
      server_type   = "SMALL-1C-2G"
    },
  ]
}
```

Add a load balancer:

```hcl
# ...main.tf

resource "elestio_load_balancer" "load_balancer" {
  project_id    = elestio_project.project.id
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
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

Finally, let's add some outputs to retrieve useful information when the cluster is ready:

```hcl
# ...main.tf

output "database_admin" {
  value     = elestio_postgresql.database.admin
  sensitive = true
}

output "nodes_admins" {
  value     = { for node in module.cluster.nodes : node.server_name => node.admin }
  sensitive = true
}

output "load_balancer_cname" {
  value = elestio_load_balancer.load_balancer.cname
}
```

### 3. Run the configuration

You can now run `terraform init` and `terraform apply` to create your Keycloak cluster.
After a few minutes, the cluster will be ready to use.
You can access your outputs with `terraform output`:

```bash
$ terraform output database_admin
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

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nodes"></a> [nodes](#output\_nodes) | This is the created nodes full information |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_elestio"></a> [elestio](#provider\_elestio) | = 0.13.0 |
| <a name="provider_null"></a> [null](#provider\_null) | = 3.2.0 |
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_elestio"></a> [elestio](#requirement\_elestio) | = 0.13.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | = 3.2.0 |
## Resources

| Name | Type |
|------|------|
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/0.13.0/docs/resources/keycloak) | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/3.2.0/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->
