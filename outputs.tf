# outputs.tf
# docker_container.nginx and docker_container.postgres no longer exist
# in root — they are now inside modules. Access via module.nginx and
# module.postgres which proxy through the module's outputs.tf.

output "nginx_url" {
  description = "URL to reach nginx"
  value       = module.nginx.url
}

output "postgres_connection" {
  description = "Postgres connection string"
  value       = "postgresql://${var.db_user}@localhost:${var.postgres_port}/${var.db_name}"
  # password deliberately excluded from output
}

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.app.id
}

output "container_ids" {
  description = "Map of container names to IDs"
  # sensitive   = true
  value = {
    # nginx    = module.nginx.container_id
    # postgres = module.postgres.container_id
    nginx    = nonsensitive(module.nginx.container_id)
    postgres = nonsensitive(module.postgres.container_id)
  }
}

output "container_names" {
  description = "Map of container names"
  #sensitive   = true
  value = {
   # nginx    = module.nginx.container_name
   # postgres = module.postgres.container_name
    nginx    = nonsensitive(module.nginx.container_name)
    postgres = nonsensitive(module.postgres.container_name)
  }
}

output "environment_summary" {
  description = "Human-readable summary of what was deployed"
  value = {
    env         = var.env
    project     = var.project
    name_prefix = local.name_prefix
    is_prod     = local.is_prod
  }
}

