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
