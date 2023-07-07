# If you are unfamiliar with Terraform, this file could look a bit scary.
# Don't worry, it's not that complicated. You can read the comments one by one to understand the process.

terraform {
  required_version = ">= 0.13"
  required_providers {
    elestio = {
      # TODO: use latest version with load_balancer support
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = var.elestio_email
  api_token = var.elestio_api_token
}

# We create a project to group all the resources we will create.
resource "elestio_project" "project" {
  name             = "Keycloak Cluster"
  technical_emails = var.elestio_email
}

# We create a postgresql database to store the keycloak data.
resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  server_name   = "database"
  provider_name = "scaleway"
  datacenter    = "fr-par-1"
  server_type   = "SMALL-2C-2G"
  support_level = "level1"
  admin_email   = var.elestio_email
  ssh_keys      = []
}

# The module will create, configure and link the keycloak nodes
module "keycloak_cluster" {
  source           = "../.."
  project_id       = elestio_project.project.id
  keycloak_version = "latest"
  nodes = [
    // You can add more nodes to your cluster by adding more objects to this list.
    {
      server_name   = "keycloak-1"
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      server_type   = "SMALL-2C-2G"
      support_level = "level1"
      admin_email   = var.elestio_email
    },
    {
      server_name   = "keycloak-2"
      provider_name = "scaleway"
      datacenter    = "fr-par-1"
      server_type   = "SMALL-2C-2G"
      support_level = "level1"
      admin_email   = var.elestio_email
    }
  ]
  global_ssh_key = {
    key_name    = "admin"                   # or var.ssh_key.name
    public_key  = file("~/.ssh/id_rsa.pub") # or var.ssh_key.public_key
    private_key = file("~/.ssh/id_rsa")     # or var.ssh_key.private_key
  }
  postgresql_host     = elestio_postgresql.database_admin.host
  postgresql_port     = elestio_postgresql.database_admin.port
  postgresql_database = "keycloak"
  postgresql_username = elestio_postgresql.database_admin.user
  postgresql_password = elestio_postgresql.database_admin.password
}

# Finally, we create a load balancer to expose all the keycloak nodes on the same IP address.
resource "elestio_load_balancer" "load_balancer" {
  project_id    = elestio_project.project.id
  provider_name = "scaleway"
  datacenter    = "fr-par-1"
  server_type   = "SMALL-2C-2G"
  config = {
    target_services = module.keycloak_cluster.keycloak_nodes[*].id
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
