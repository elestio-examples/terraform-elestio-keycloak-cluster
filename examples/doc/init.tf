terraform {
  required_providers {
    elestio = {
      source = "elestio/elestio"
    }
  }
}

provider "elestio" {
  email     = "xxxx@xxxx.xxx"
  api_token = "xxxxxxxxxxxxx"
}

resource "elestio_project" "project" {
  name = "Keycloak Cluster"
}
