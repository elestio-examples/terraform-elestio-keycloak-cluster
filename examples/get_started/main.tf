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

resource "elestio_project" "project" {
  name             = "Keycloak Cluster"
  technical_emails = var.elestio_email
}

module "keycloak_cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"
  # source = "../.." # Use this line to test the module locally

  project_id = elestio_project.project.id
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
    key_name    = var.ssh_key_name
    public_key  = var.ssh_public_key
    private_key = var.ssh_private_key
  }
  nodes = [
    {
      server_name   = "keycloak-germany"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
    },
    {
      server_name   = "keycloak-finlande"
      provider_name = "hetzner"
      datacenter    = "hel1"
      server_type   = "SMALL-1C-2G"
    },
    # You can add more nodes here, but you need to have enough resources quota
    # You can see and udpdate your resources quota on https://dash.elest.io/account/add-quota
  ]
}

output "keycloak_admin" {
  value     = module.keycloak_cluster.keycloak_admin
  sensitive = true
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
