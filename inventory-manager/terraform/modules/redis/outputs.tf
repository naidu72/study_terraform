output "service_name" {
  description = "Redis service name"
  value       = kubernetes_service.redis.metadata[0].name
}

output "service_port" {
  description = "Redis service port"
  value       = kubernetes_service.redis.spec[0].port[0].port
}

output "deployment_name" {
  description = "Redis deployment name"
  value       = kubernetes_deployment.redis.metadata[0].name
}

output "pvc_name" {
  description = "Redis PVC name"
  value       = kubernetes_persistent_volume_claim.redis.metadata[0].name
}
