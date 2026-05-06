output "service_name" {
  description = "Backend service name"
  value       = kubernetes_service.backend.metadata[0].name
}

output "service_port" {
  description = "Backend service port"
  value       = kubernetes_service.backend.spec[0].port[0].port
}

output "deployment_name" {
  description = "Backend deployment name"
  value       = kubernetes_deployment.backend.metadata[0].name
}

output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = var.enable_ingress
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.enable_ingress ? var.ingress_host : null
}

output "secret_name" {
  description = "Backend secret name"
  value       = kubernetes_secret.backend.metadata[0].name
}

output "configmap_name" {
  description = "Backend ConfigMap name"
  value       = kubernetes_config_map.backend.metadata[0].name
}

output "init_job_name" {
  description = "Database initialization job name"
  value       = kubernetes_job.init_db.metadata[0].name
}
