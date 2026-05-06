# Namespace Outputs
output "namespace" {
  description = "Kubernetes namespace name"
  value       = module.namespace.name
}

# PostgreSQL Outputs
output "postgres_service" {
  description = "PostgreSQL service name"
  value       = module.postgresql.service_name
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${var.postgres_user}:${var.postgres_password}@${module.postgresql.service_name}.${module.namespace.name}.svc.cluster.local:5432/${var.postgres_database}"
  sensitive   = true
}

# Redis Outputs
output "redis_service" {
  description = "Redis service name"
  value       = module.redis.service_name
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${module.redis.service_name}.${module.namespace.name}.svc.cluster.local:6379/0"
}

# Backend Outputs
output "backend_service" {
  description = "Backend service name"
  value       = module.backend.service_name
}

output "backend_service_url" {
  description = "Backend service URL (internal)"
  value       = "http://${module.backend.service_name}.${module.namespace.name}.svc.cluster.local:8000"
}

# Frontend Outputs
output "frontend_service" {
  description = "Frontend service name"
  value       = module.frontend.service_name
}

output "frontend_service_url" {
  description = "Frontend service URL (internal)"
  value       = module.frontend.service_url
}

output "frontend_ingress_host" {
  description = "Frontend ingress hostname"
  value       = module.frontend.ingress_host
}

output "frontend_ingress_url" {
  description = "Frontend public URL"
  value       = module.frontend.ingress_url
}

# Ingress Outputs
output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = var.enable_ingress
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.enable_ingress ? var.ingress_host : "N/A"
}

# Application Info
output "application_info" {
  description = "Application deployment information"
  value = {
    namespace         = module.namespace.name
    backend_replicas  = var.backend_replicas
    backend_image     = var.backend_image
    frontend_replicas = var.frontend_replicas
    frontend_image    = var.frontend_image
    environment       = var.environment
  }
}
