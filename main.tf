resource "elestio_keycloak" "nodes" {
  for_each = { for key, value in var.nodes : key => value }

  project_id       = var.project_id
  version          = var.keycloak_version
  server_name      = each.value.server_name
  default_password = var.keycloak_admin_password
  provider_name    = each.value.provider_name
  datacenter       = each.value.datacenter
  server_type      = each.value.server_type
  support_level    = each.value.support_level
  admin_email      = each.value.admin_email
  ssh_keys         = contact(each.value.ssh_keys, [var.global_ssh_key])

  connection {
    type        = "ssh"
    host        = self.ipv4
    private_key = var.global_ssh_key.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/app",
      "docker-compose down",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/resources/docker-compose.yml"
    destination = "/opt/app/docker-compose.yml"
  }
}

// The .env file contains some variables that change depending on the number of nodes
// Triggering this resource when the number of nodes changes allows us to update the .env file
// of each nodes and restart the docker-compose
resource "null_resource" "nodes_configuration" {
  for_each = elestio_keycloak.nodes

  triggers = {
    cluster_nodes_ids = join(",", elestio_keycloak.nodes[*].id)
  }

  connection {
    type        = "ssh"
    host        = each.ipv4
    private_key = var.global_ssh_key.private_key
  }

  provisioner "file" {
    content = templatefile("${path.module}/resources/.env.tftpl", {
      software_password       = each.value.admin.password
      software_version        = each.value.version
      postgresql_host         = var.postgresql_host
      postgresql_port         = var.postgresql_port
      postgresql_database     = var.postgresql_database
      postgresql_schema       = var.postgresql_schema
      postgresql_username     = var.postgresql_username
      postgresql_password     = var.postgresql_password
      keycloak_admin_user     = var.keycloak_admin_user
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
