# modules/docker-service/outputs.tf
# All references go through local.container which collapses
# docker_container.protected and docker_container.unprotected
# into one reference regardless of which is active.

output "container_id" {
  description = "Docker container ID"
  value       = local.container.id
}

output "container_name" {
  description = "Docker container name"
  value       = local.container.name
}

output "host_port" {
  description = "The port this service is reachable on via localhost"
  value       = var.external_port
}

output "url" {
  description = "Convenience URL for HTTP services"
  value       = "http://localhost:${var.external_port}"
}

