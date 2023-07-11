# This example show how to create a Keycloak Cluster with Elestio from scratch.
# It will :
# 1. Create a project
# 2. Create a postgresql service
# 3. Use the module to create the keycloak nodes linked to the postgresql database
# 4. Create a load balancer to expose the keycloak nodes on a single IP address

terraform {
  required_version = ">= 0.13"
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

# You can use them in your config with the syntax: local.<variable_name> (e.g. local.database_name).
# Do not use it to store sensitive data, use variables.tf and secrets.tfvars instead.
locals {
  database_name = "keycloak"
  ssh_key = {
    name        = "admin"
    public_key  = file("~/.ssh/id_rsa.pub")
    private_key = file("~/.ssh/id_rsa")
  }
}

resource "elestio_project" "project" {
  name             = "Keycloak Cluster"
  technical_emails = var.elestio_email
}

resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  server_name   = "postgres"
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
  support_level = "level1"
  admin_email   = var.elestio_email
  ssh_keys = [
    {
      key_name   = local.ssh_key.name
      public_key = local.ssh_key.public_key
    }
  ]

  # Connect to the service to create the specific database for keycloak.
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = self.ipv4
      private_key = local.ssh_key.private_key
    }

    inline = [
      "cd /opt/app",
      "docker exec -it postgres psql -U ${self.database_admin.user} -c 'CREATE DATABASE \"${local.database_name}\";'"
    ]
  }
}

# This this how you use the module to create a keycloak cluster.
# The module will create the nodes and configure them to work together.
module "keycloak_cluster" {
  source = "../.."

  project_id              = elestio_project.project.id
  postgresql_database     = local.database_name
  postgresql_host         = elestio_postgresql.database.database_admin.host
  postgresql_port         = elestio_postgresql.database.database_admin.port
  postgresql_username     = elestio_postgresql.database.database_admin.user
  postgresql_password     = elestio_postgresql.database.database_admin.password
  keycloak_admin_password = var.keycloak_admin_password
  global_ssh_key = {
    # This key will be added to all nodes, so that Terraform can connect to them
    key_name    = local.ssh_key.name
    public_key  = local.ssh_key.public_key
    private_key = local.ssh_key.private_key
  }
  nodes = [
    {
      server_name   = "keycloak-germany"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
      admin_email   = var.elestio_email
    },
    {
      server_name   = "keycloak-finlande"
      provider_name = "hetzner"
      datacenter    = "hel1"
      server_type   = "SMALL-1C-2G"
      admin_email   = var.elestio_email
    },
    # You can add more nodes here, but you need to have enough resources quota
    # You can see and udpdate your resources quota on https://dash.elest.io/account/add-quota
  ]
}

resource "elestio_load_balancer" "load_balancer" {
  project_id    = elestio_project.project.id
  provider_name = "hetzner"
  datacenter    = "fsn1"
  server_type   = "SMALL-1C-2G"
  config = {
    # Provide the id of the keycloak nodes to forward the traffic to.
    target_services = [for node in module.keycloak_cluster.keycloak_nodes : node.id]
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
