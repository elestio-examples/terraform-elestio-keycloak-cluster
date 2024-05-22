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
  name = "keycloak-cluster"
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
      "docker-compose exec -T postgres psql -U postgres -c 'CREATE DATABASE keycloak'"
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
    sticky_session_enabled = true
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
