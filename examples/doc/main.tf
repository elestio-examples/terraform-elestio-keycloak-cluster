module "keycloak_cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id = "1234"
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
    key_name    = "admin"
    public_key  = file("~/.ssh/id_rsa.pub")
    private_key = file("~/.ssh/id_rsa")
  }
  nodes = [
    {
      server_name   = "keycloak-germany"
      provider_name = "hetzner"
      datacenter    = "fsn1"
      server_type   = "SMALL-1C-2G"
      admin_email   = "admin-germany@email.com"
    },
    {
      server_name   = "keycloak-finlande"
      provider_name = "hetzner"
      datacenter    = "hel1"
      server_type   = "SMALL-1C-2G"
      admin_email   = "admin-finlande@email.com"
    },
    # You can add more nodes here, but you need to have enough resources quota
    # You can see and udpdate your resources quota on https://dash.elest.io/account/add-quota
  ]
}

output "keycloak_admin" {
  value     = module.keycloak_cluster.keycloak_admin
  sensitive = true
}
