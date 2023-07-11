resource "elestio_postgresql" "database" {
  count = var.postgresql != null ? 0 : 1

  project_id    = var.project_id
  server_name   = "postgres-keycloak"
  provider_name = var.nodes[0].provider_name
  datacenter    = var.nodes[0].datacenter
  server_type   = var.nodes[0].server_type
  support_level = var.nodes[0].support_level
  admin_email   = var.nodes[0].admin_email
  ssh_keys = [{
    key_name   = var.ssh_key.key_name
    public_key = var.ssh_key.public_key
  }]

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.ssh_key.private_key
  }

  # Connect to the service to create the specific database for keycloak.
  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker exec -it postgres psql -U ${self.database_admin.user} -c 'CREATE DATABASE keycloak;'"
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
  support_level    = each.value.support_level
  admin_email      = each.value.admin_email
  ssh_keys         = concat(each.value.ssh_keys, [var.ssh_key])

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.ssh_key.private_key
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
    private_key = var.ssh_key.private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/resources/.env.tftpl", {
      software_password       = each.value.admin.password
      software_version        = each.value.version
      postgresql_host         = var.postgresql != null ? var.postgresql.host : elestio_postgresql.database[0].cname
      postgresql_port         = var.postgresql != null ? var.postgresql.port : elestio_postgresql.database[0].database_admin.port
      postgresql_database     = var.postgresql != null ? var.postgresql.database : "keycloak"
      postgresql_schema       = var.postgresql != null ? var.postgresql.schema : "public"
      postgresql_username     = var.postgresql != null ? var.postgresql.username : elestio_postgresql.database[0].database_admin.user
      postgresql_password     = var.postgresql != null ? var.postgresql.password : elestio_postgresql.database[0].database_admin.password
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
