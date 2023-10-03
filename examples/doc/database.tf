resource "elestio_postgresql" "database" {
  project_id    = elestio_project.project.id
  provider_name = "scaleway"
  datacenter    = "fr-par-1"
  server_type   = "SMALL-2C-2G"
}
