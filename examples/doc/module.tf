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
