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
      server_type   = "MEDIUM-2C-4G"
    },
    {
      server_name   = "keycloak-02"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "MEDIUM-2C-4G"
    },
  ]

  configuration_ssh_key = {
    username    = "terraform-user"
    public_key  = chomp(file("~/.ssh/id_rsa.pub"))
    private_key = file("~/.ssh/id_rsa")
  }
}
