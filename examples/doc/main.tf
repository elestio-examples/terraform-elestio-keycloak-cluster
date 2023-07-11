module "cluster" {
  source = "elestio-examples/keycloak-cluster/elestio"

  project_id              = "1234"
  postgresql_database     = "keycloak"
  postgresql_host         = "my-postgresql-host.elest.io"
  postgresql_port         = "5432"
  postgresql_username     = "admin"
  postgresql_password     = var.postgresql_password
  keycloak_admin_password = var.keycloak_admin_password
  global_ssh_key = {
    # This key will be added to all nodes, so that Terraform can connect to them
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
