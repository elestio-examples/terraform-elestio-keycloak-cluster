# Terraform Module Keycloak Cluster

A terraform module created by [Elestio](https://elest.io/fully-managed-services) that simplifies Keycloak cluster deployment and scaling.

## Why Keycloak?

Keycloak is a powerful tool for managing user access to your applications. It helps you save money, speed up development, and ensures top-level security.

## Keycloak Cluster Architecture

In a Keycloak cluster, multiple independent nodes use a distributed Infinispan cache to share user sessions and data. The cluster can scale horizontally and ensure high availability.

![Cluster architecture](documentation/cluster_architecture.png)

## Terraform Architecture

This module by itself only deploys keycloak nodes. It's designed to be used in conjunction with other services, a load balancer and a database. Elestio provides those services so we will use them in the example below. You can also use your own services in the configuration, just make sure they are compatible with Keycloak.

![Terraform architecture](documentation/terraform_architecture.png)

## Elestio

Elestio is a Fully Managed DevOps platform that helps you deploy services without spending weeks configuring them (security, dns, smtp, ssl, monitoring/alerts, backups, updates). If you want to use this module, you will need an Elestio account.

- [Create an account](https://dash.elest.io/signup)
- [Request the free credits](https://docs.elest.io/books/billing/page/free-trial)

The list of all services you can deploy with Elestio is [here](https://elest.io/fully-managed-services). The list is growing, so if you don't see what you need, let us know.
