resource "elestio_keycloak" "nodes" {
  for_each = { for value in var.nodes : value.server_name => value }

  project_id       = var.project_id
  version          = var.keycloak_version
  default_password = var.keycloak_password
  server_name      = each.value.server_name
  provider_name    = each.value.provider_name
  datacenter       = each.value.datacenter
  server_type      = each.value.server_type
  ssh_public_keys = concat(each.value.ssh_public_keys, [{
    username = var.configuration_ssh_key.username
    key_data = var.configuration_ssh_key.public_key
  }])

  // Optional attributes
  admin_email                                       = each.value.admin_email
  alerts_enabled                                    = each.value.alerts_enabled
  app_auto_updates_enabled                          = each.value.app_auto_update_enabled
  backups_enabled                                   = each.value.backups_enabled
  custom_domain_names                               = each.value.custom_domain_names
  firewall_enabled                                  = each.value.firewall_enabled
  keep_backups_on_delete_enabled                    = each.value.keep_backups_on_delete_enabled
  remote_backups_enabled                            = each.value.remote_backups_enabled
  support_level                                     = each.value.support_level
  system_auto_updates_security_patches_only_enabled = each.value.system_auto_updates_security_patches_only_enabled

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose down",
      "rm -rf postgres_data postgresql_data docker-compose.yml docker-compose.yaml",
    ]
  }
}

# The .env file contains some variables that change depending on the number of nodes
# Triggering this resource when the number of nodes changes allows us to update the .env file
# of each nodes and restart the docker-compose
resource "null_resource" "update_nodes_env" {
  for_each = { for node in elestio_keycloak.nodes : node.server_name => node }

  triggers = {
    cluster_nodes_ids = join(",", [for node in elestio_keycloak.nodes : node.id])
  }

  connection {
    type        = "ssh"
    host        = each.value.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "file" {
    source      = "${path.module}/resources/docker-compose.yml"
    destination = "/opt/app/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/resources/cache-ispn-tcp-ping.xml"
    destination = "/opt/app/cache-ispn-tcp-ping.xml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/resources/.env.tftpl", {
      software_version  = each.value.version
      software_password = each.value.admin.password
      admin_email       = each.value.admin_email
      current_node      = each.value
      nodes             = elestio_keycloak.nodes
      database          = var.database
      database_host     = var.database_host
      database_port     = var.database_port
      database_name     = var.database_name
      database_schema   = var.database_schema
      database_user     = var.database_user
      database_password = var.database_password
    })
    destination = "/opt/app/.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose up -d",
      "sleep 15" // Wait for keycloak to be up
    ]
  }
}
