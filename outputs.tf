output "keycloak_nodes" {
  value       = elestio_keycloak.nodes
  description = "List of nodes of the Keycloak cluster"
}

output "keycloak_admin" {
  value       = { for node in elestio_keycloak.nodes : node.server_name => node.admin }
  description = "The URL and secrets to connectg to Keycloak Admin on each nodes"
}
