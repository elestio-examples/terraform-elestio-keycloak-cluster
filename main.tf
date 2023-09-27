// This database resource is created only if the postgresql.create variable is provided
resource "elestio_postgresql" "database" {
  count = var.postgresql.create != null ? 1 : 0

  project_id    = var.project_id
  provider_name = var.postgresql.create.provider_name
  datacenter    = var.postgresql.create.datacenter
  server_type   = var.postgresql.create.server_type
  ssh_public_keys = concat(var.postgresql.create.ssh_public_keys, [{
    username = var.configuration_ssh_key.username
    key_data = var.configuration_ssh_key.public_key
  }])

  // Optional attributes
  server_name                                       = var.postgresql.create.server_name
  version                                           = var.postgresql.create.version
  default_password                                  = var.postgresql.create.default_password
  admin_email                                       = var.postgresql.create.admin_email
  alerts_enabled                                    = var.postgresql.create.alerts_enabled
  app_auto_updates_enabled                          = var.postgresql.create.app_auto_update_enabled
  backups_enabled                                   = var.postgresql.create.backups_enabled
  firewall_enabled                                  = var.postgresql.create.firewall_enabled
  keep_backups_on_delete_enabled                    = var.postgresql.create.keep_backups_on_delete_enabled
  remote_backups_enabled                            = var.postgresql.create.remote_backups_enabled
  support_level                                     = var.postgresql.create.support_level
  system_auto_updates_security_patches_only_enabled = var.postgresql.create.system_auto_updates_security_patches_only_enabled

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.configuration_ssh_key.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker exec -it postgres psql -U ${self.database_admin.user} -c 'CREATE DATABASE ${var.postgresql.create.database_name};'"
    ]
  }
}

resource "elestio_keycloak" "nodes" {
  for_each = { for value in var.nodes : value.server_name => value }

  project_id       = var.project_id
  version          = var.keycloak_version
  server_name      = each.value.server_name
  default_password = var.keycloak_admin_password
  provider_name    = each.value.provider_name
  datacenter       = each.value.datacenter
  server_type      = each.value.server_type

  // Merge the module configuration_ssh_key with the optional ssh_public_keys attribute
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
      "rm -rf postgresql_data"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/resources/docker-compose.yml"
    destination = "/opt/app/docker-compose.yml"
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
    content = templatefile("${path.module}/resources/.env.tftpl", {
      software_password       = each.value.admin.password
      software_version        = each.value.version
      postgresql_host         = var.postgresql.use != null ? var.postgresql.use.host : elestio_postgresql.database[0].cname
      postgresql_port         = var.postgresql.use != null ? var.postgresql.use.port : elestio_postgresql.database[0].database_admin.port
      postgresql_database     = var.postgresql.use != null ? var.postgresql.use.database : var.postgresql.create.database_name
      postgresql_schema       = var.postgresql.use != null ? var.postgresql.use.schema : "public"
      postgresql_username     = var.postgresql.use != null ? var.postgresql.use.username : elestio_postgresql.database[0].database_admin.user
      postgresql_password     = var.postgresql.use != null ? var.postgresql.use.password : elestio_postgresql.database[0].database_admin.password
      keycloak_admin_user     = "root"
      keycloak_admin_password = var.keycloak_admin_password
      node_ipv4               = each.value.ipv4
      nodes_count             = length(elestio_keycloak.nodes)
    })
    destination = "/opt/app/.env"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose up -d",
    ]
  }
}

resource "elestio_load_balancer" "load_balancer" {
  count = var.load_balancer != null ? 1 : 0

  project_id    = var.project_id
  provider_name = var.load_balancer.provider_name
  datacenter    = var.load_balancer.datacenter
  server_type   = var.load_balancer.server_type
  config = {
    # We provide the id of the keycloak nodes to forward the traffic to.
    target_services = [for node in elestio_keycloak.nodes : node.id]
    forward_rules = [
      {
        port            = "443"
        protocol        = "HTTPS"
        target_port     = "443"
        target_protocol = "HTTPS"
      },
    ]
    access_logs_enabled      = var.load_balancer.config != null ? var.load_balancer.config.access_logs_enabled : null
    ip_rate_limit_enabled    = var.load_balancer.config != null ? var.load_balancer.config.ip_rate_limit_enabled : null
    ip_rate_limit_per_second = var.load_balancer.config != null ? var.load_balancer.config.ip_rate_limit_per_second : null
    output_cache_in_seconds  = var.load_balancer.config != null ? var.load_balancer.config.output_cache_in_seconds : null
    proxy_protocol_enabled   = var.load_balancer.config != null ? var.load_balancer.config.proxy_protocol_enabled : null
    remove_response_headers  = var.load_balancer.config != null ? var.load_balancer.config.remove_response_headers : null
    sticky_sessions_enabled  = var.load_balancer.config != null ? var.load_balancer.config.sticky_sessions_enabled : null
  }
}
