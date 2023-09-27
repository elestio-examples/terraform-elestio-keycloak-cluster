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
  name = "keycloak-cluster"
}

module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id              = elestio_project.project.id
  keycloak_version        = null # if null the latest version will be installed
  keycloak_admin_password = var.keycloak_password

  configuration_ssh_key = {
    # https://registry.terraform.io/providers/elestio/elestio/latest/docs/guides/ssh_keys
    username    = "admin"
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
