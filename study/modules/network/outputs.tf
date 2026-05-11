output "network_name" {
  description = "Name of the created Docker network"
  value       = docker_network.this.name
}

output "network_id" {
  description = "ID of the created Docker network"
  value       = docker_network.this.id
}
