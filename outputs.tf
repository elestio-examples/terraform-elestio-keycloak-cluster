output "keycloak_database" {
  value       = elestio_postgresql.database
  description = "This is the database information if you let the module create one for you (`postgres = null` in the config)"
}

output "keycloak_nodes" {
  value       = elestio_keycloak.nodes
  description = "List of nodes of the Keycloak cluster"
}

output "keycloak_admin" {
  value       = { for node in elestio_keycloak.nodes : node.server_name => node.admin }
  description = "The URL and secrets to connect to Keycloak Admin on each nodes"
}
