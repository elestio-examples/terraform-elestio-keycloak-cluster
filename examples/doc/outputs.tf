# ...main.tf

output "database_admin" {
  value     = elestio_postgresql.database.admin
  sensitive = true
}

output "nodes_admins" {
  value     = { for node in module.cluster.nodes : node.server_name => node.admin }
  sensitive = true
}

output "load_balancer_cname" {
  value = elestio_load_balancer.load_balancer.cname
}
