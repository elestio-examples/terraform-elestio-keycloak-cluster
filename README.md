# Keycloak Cluster - Terraform Module by Elestio

A terraform module created by [Elestio](https://elest.io/fully-managed-services) that simplifies Keycloak cluster deployment and scaling.

## Why Keycloak?

Keycloak is a powerful tool for managing user access to your applications. It helps you save money, speed up development, and ensures top-level security.

## Keycloak Cluster Architecture

In a Keycloak cluster, multiple independent nodes use a distributed Infinispan cache to share user sessions and data. The cluster can scale horizontally and ensure high availability.

![Cluster architecture](documentation/cluster_architecture.png)

## Terraform Architecture

This module by itself only deploys keycloak nodes. It's designed to be used in conjunction with other services, a load balancer and a database. Elestio provides those services so we will use them in the example below. You can also use your own services in the configuration, just make sure they are compatible with Keycloak.

![Terraform architecture](documentation/terraform_architecture.png)

## Elestio

Elestio is a Fully Managed DevOps platform that helps you deploy services without spending weeks configuring them (security, dns, smtp, ssl, monitoring/alerts, backups, updates). If you want to use this module, you will need an Elestio account.

- [Create an account](https://dash.elest.io/signup)
- [Request the free credits](https://docs.elest.io/books/billing/page/free-trial)

The list of all services you can deploy with Elestio is [here](https://elest.io/fully-managed-services). The list is growing, so if you don't see what you need, let us know.

## Usage

If you want to use this module with your own database and load balancer, you can do so:

```hcl
module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id        = "12345"
  keycloak_version  = "latest"
  keycloak_password = "MyPassword1234"

  database          = "postgres"
  database_host     = "hostname.example.com"
  database_port     = "5432"
  database_name     = "keycloak"
  database_schema   = "public"
  database_user     = "admin"
  database_password = "password"

  nodes = [
    {
      server_name   = "keycloak-01"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      server_name   = "keycloak-02"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
  ]

  configuration_ssh_key = {
    username    = "terraform-user"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }
}
```

## Complete Example

If you want to deploy everything at once (database, load balancer, and nodes), you can follow this example.

We will do the following:

- Install terraform and copy a ready-to-use configuration
- Deploy the cluster with 2 nodes
- Output the cluster information
- Verify that it's working
- Add a third node

### Install Terraform

First, let's install the Terraform client on your machine: https://learn.hashicorp.com/tutorials/terraform/install-cli

<details><summary>Instructions for MacOS:</summary>

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -v
```

</details>

### Copy the configuration

Create a new directory and the following files step by step:

```response
.
├── main.tf
├── terraform.tfvars
├── terraform_rsa
├── terraform_rsa.pub
└── .gitignore
```

<details><summary>Create `main.tf` file with this content:</summary>

```hcl
terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

# Set the variables values in the `terraform.tfvars` file
variable "elestio_email" {
  type      = string
  sensitive = true
}
variable "elestio_api_token" {
  type      = string
  sensitive = true
}
variable "keycloak_password" {
  type      = string
  sensitive = true
}

provider "elestio" {
  email     = var.elestio_email
  api_token = var.elestio_api_token
}

resource "elestio_project" "project" {
  name = "Keycloak Cluster"
}

locals {
  ssh_key_name         = "terraform"
  ssh_public_key_path  = "./terraform_rsa.pub"
  ssh_private_key_path = "./terraform_rsa"
}

resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
  ssh_public_keys = [{
    username = local.ssh_key_name
    key_data = chomp(file(local.ssh_public_key_path))
  }]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.ipv4
      private_key = file(local.ssh_private_key_path)
    }

    // It create a dedicated database name for Keycloak
    inline = [
      "cd /opt/app",
      "docker exec -i postgres psql -U postgres -c 'CREATE DATABASE keycloak'"
    ]
  }
}

module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id        = elestio_project.project.id
  keycloak_version  = "latest"
  keycloak_password = var.keycloak_password

  database          = "postgres"
  database_host     = elestio_postgresql.database.cname
  database_port     = elestio_postgresql.database.database_admin.port
  database_name     = "keycloak"
  database_schema   = "public"
  database_user     = elestio_postgresql.database.database_admin.user
  database_password = elestio_postgresql.database.database_admin.password

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

  configuration_ssh_key = {
    username    = local.ssh_key_name
    public_key  = chomp(file(local.ssh_public_key_path))
    private_key = file(local.ssh_private_key_path)
  }
}

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

</details>

<details><summary>Create `terraform.tfvars` file with this content and fill it with your sensitive information:</summary>

```hcl
# Generate your Elestio API token: https://dash.elest.io/account/security
elestio_email     = ""
elestio_api_token = ""

# Generate a safe password: https://api.elest.io/api/auth/passwordgenerator
keycloak_password = ""
```

</details>

<details><summary>Generate a dedicated SSH Key (required by the module to configure the nodes):</summary>

```bash
ssh-keygen -t rsa -f terraform_rsa
```

</details>

<details><summary>If you want to commit your code, create `.gitignore` file with this content:</summary>

```plaintext
# Your new SSH key
terraform_rsa.pub
terraform_rsa

# Local .terraform directories
**/.terraform/*
**/.terraform

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data, such as
# password, private keys, and other secrets. These should not be part of version
# control as they are data points which are potentially sensitive and subject
# to change depending on the environment.
*.tfvars
*.tfvars.json

# Ignore override files as they are usually used to override resources locally and so
# are not checked in
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc
```

</details>

Your configuration is ready.

### Deploy the cluster

Run the following commands:

```bash
terraform init
terraform apply
```

It will ask you to confirm the deployment. Type `yes` and press `Enter`.

The deployment will take a few minutes.

### Output the cluster information

You can show all the information about the created resources with the `terraform show` command.

```bash
terraform show
```

The output is large so you can use the custom outputs for essential information.

The access information of your database:

```bash
terraform output database_admin
```

```response
// TODO: Add the response example
```

The access information of your nodes:

```bash
terraform output nodes_admins
```

```response
// TODO: Add the response example
```

And the cname of the load balancer:

```bash
terraform output load_balancer_cname
```

```response
// TODO: Add the response example
```

## Verify that it's working

// TODO: Add the verification steps

If any node responds with an error, you can replace it by :

- Changing the `server_name` in `main.tf` and running `terraform apply`.
- Or removing the node from the `nodes` attribute and running `terraform apply`. Then add it back and run `terraform apply` again.

## Add a third node

You can add new nodes to the cluster by adding them to the `nodes` attribute in the `main.tf`.

```hcl
nodes = [
  {
    server_name   = "keycloak-01"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },
  {
    server_name   = "keycloak-02"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },
  # You can add more nodes here
  {
    server_name   = "keycloak-03"
    provider_name = "hetzner"
    datacenter    = "fsn1"
    server_type   = "SMALL-1C-2G"
  },
]
```

If you run `terraform apply` again, it will ask you to confirm the deployment.
Type `yes` and press `Enter`.
The new node will join the cluster in a few minutes.

## Recommendations

**Secrets** - Do not commit your API token, Keycloak password, SSH key...

**Configuration** - If you want to know all available attributes, check the [clickhouse service documentation](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/clickhouse). E.g. you can disable the service firewall with `firewall_enabled = false`.

**Hosting** - Look this guide [Providers, Datacenters and Server Types](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/providers_datacenters_server_types) to know about the available options.

**Resources limit** - If you add more nodes, you may attains the resources limit of your account, please visit your account [quota page](https://dash.elest.io/account/add-quota) to ask for more resources.

If you need any help, please contact us at [contact@elest.io](mailto:contact@elest.io).
We are always happy to help you with any questions you may have.

## Inputs

| Name                                                                                             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Default      | Required |
| ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | :------: |
| <a name="input_configuration_ssh_key"></a> [configuration_ssh_key](#input_configuration_ssh_key) | After the nodes are created, Terraform must connect to apply some custom configuration.<br>This configuration is done using SSH from your local machine.<br>The Public Key will be added to the nodes and the Private Key will be used by your local machine to connect to the nodes.<br><br>Read the guide [\"How generate a valid SSH Key for Elestio\"](https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys). Example:<pre>configuration_ssh_key = {<br> username = "admin"<br> public_key = chomp(file("\~/.ssh/id_rsa.pub"))<br> private_key = file("\~/.ssh/id_rsa")<br>}</pre> | <pre>object({<br> username = string<br> public_key = string<br> private_key = string<br> })</pre>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | n/a          |   yes    |
| <a name="input_database"></a> [database](#input_database)                                        | Allowed values are `postgres`, `cockroach`, `mariadb`, `mysql`, `oracle`, or `mssql`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"postgres"` |    no    |
| <a name="input_database_host"></a> [database_host](#input_database_host)                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |
| <a name="input_database_name"></a> [database_name](#input_database_name)                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"keycloak"` |    no    |
| <a name="input_database_password"></a> [database_password](#input_database_password)             | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |
| <a name="input_database_port"></a> [database_port](#input_database_port)                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"5432"`     |    no    |
| <a name="input_database_schema"></a> [database_schema](#input_database_schema)                   | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"public"`   |    no    |
| <a name="input_database_user"></a> [database_user](#input_database_user)                         | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |
| <a name="input_keycloak_password"></a> [keycloak_password](#input_keycloak_password)             | Rules: Alphanumeric characters or hyphens `-`, +10 characters, +1 digit, +1 uppercase, +1 lowercase.<br>If you need a valid strong password, you can generate one accessing this Elestio URL: https://api.elest.io/api/auth/passwordgenerator                                                                                                                                                                                                                                                                                                                                                                         | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |
| <a name="input_keycloak_version"></a> [keycloak_version](#input_keycloak_version)                | The module uses the Keycloak image from the phasetwo repository. Check the available versions at: https://quay.io/repository/phasetwo/phasetwo-keycloak?tab=tags                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |
| <a name="input_nodes"></a> [nodes](#input_nodes)                                                 | Each element of this list will create an Elestio Keycloak Resource in your cluster.<br>Read the following documentation to understand what each attribute does, plus the default values: [Elestio Keycloak Resource](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak).                                                                                                                                                                                                                                                                                                         | <pre>list(<br> object({<br> server_name = string<br> provider_name = string<br> datacenter = string<br> server_type = string<br> admin_email = optional(string)<br> alerts_enabled = optional(bool)<br> app_auto_update_enabled = optional(bool)<br> backups_enabled = optional(bool)<br> custom_domain_names = optional(set(string))<br> firewall_enabled = optional(bool)<br> keep_backups_on_delete_enabled = optional(bool)<br> remote_backups_enabled = optional(bool)<br> support_level = optional(string)<br> system_auto_updates_security_patches_only_enabled = optional(bool)<br> ssh_public_keys = optional(list(<br> object({<br> username = string<br> key_data = string<br> })<br> ), [])<br> })<br> )</pre> | `[]`         |    no    |
| <a name="input_project_id"></a> [project_id](#input_project_id)                                  | n/a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | n/a          |   yes    |

## Outputs

| Name                                               | Description                                |
| -------------------------------------------------- | ------------------------------------------ |
| <a name="output_nodes"></a> [nodes](#output_nodes) | This is the created nodes full information |

## Providers

| Name                                                         | Version   |
| ------------------------------------------------------------ | --------- |
| <a name="provider_elestio"></a> [elestio](#provider_elestio) | >= 0.15.0 |
| <a name="provider_null"></a> [null](#provider_null)          | >= 3.2.0  |

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0    |
| <a name="requirement_elestio"></a> [elestio](#requirement_elestio)       | >= 0.15.0 |
| <a name="requirement_null"></a> [null](#requirement_null)                | >= 3.2.0  |

## Resources

| Name                                                                                                                    | Type     |
| ----------------------------------------------------------------------------------------------------------------------- | -------- |
| [elestio_keycloak.nodes](https://registry.terraform.io/providers/elestio/elestio/latest/docs/resources/keycloak)        | resource |
| [null_resource.update_nodes_env](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

<!-- END_TF_DOCS -->
