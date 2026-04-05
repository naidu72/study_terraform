output "nginx_url" {
  description = "URL to reach nginx"
  value       = "http://localhost:${var.nginx_port}"
}

output "postgres_connection" {
  description = "Postgres connection string"
  value       = "postgresql://${var.db_user}@localhost:${var.postgres_port}/${var.db_name}"
  # Note: password deliberately excluded from output
}

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.app.id
}

output "container_ids" {
  description = "Map of container names to IDs"
  value = {
    nginx    = docker_container.nginx.id
    postgres = docker_container.postgres.id
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