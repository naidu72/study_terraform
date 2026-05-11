# All service URLs as a map: { nginx = "http://localhost:8080", ... }
output "service_urls" {
  description = "URL for every deployed service"
  value = {
    for name, svc in module.service : name => svc.url
  }
}

# All container IDs as a map
output "container_ids" {
  description = "Docker container ID for each service"
  value = {
    for name, svc in module.service : name => svc.container_id
  }
}

# The shared network
output "network_name" {
  value = module.network.network_name
}

# Handy summary printed after apply
output "summary" {
  value = {
    environment   = var.env
    network       = module.network.network_name
    service_count = length(module.service)
    urls          = { for n, s in module.service : n => s.url }
  }
}