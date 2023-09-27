output "nodes" {
  description = "This is the created nodes full information"
  value       = elestio_keycloak.nodes
  sensitive   = true
}

output "node_admins" {
  description = "The URL and secrets to connect to Keycloak Admin on each nodes"
  value       = { for node in elestio_keycloak.nodes : node.server_name => node.admin }
  sensitive   = true
}

output "database" {
  description = "This is the created database information"
  value       = one(elestio_postgresql.database[*])
  sensitive   = true

}

output "load_balancer" {
  description = "This is the created load balancer information"
  value       = one(elestio_load_balancer.load_balancer[*])
  sensitive   = true
}
