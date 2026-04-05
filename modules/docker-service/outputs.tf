output "container_id" {
  description = "Docker container ID"
  value       = docker_container.this.id
}

output "container_name" {
  description = "Docker container name (same as var.name, for convenience)"
  value       = docker_container.this.name
}

output "host_port" {
  description = "The port this service is reachable on via localhost"
  value       = var.external_port
}

output "url" {
  description = "Convenience URL for HTTP services"
  value       = "http://localhost:${var.external_port}"
}
