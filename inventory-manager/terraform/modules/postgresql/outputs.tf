output "service_name" {
  description = "PostgreSQL service name"
  value       = kubernetes_service.postgres.metadata[0].name
}

output "service_port" {
  description = "PostgreSQL service port"
  value       = kubernetes_service.postgres.spec[0].port[0].port
}

output "statefulset_name" {
  description = "PostgreSQL StatefulSet name"
  value       = kubernetes_stateful_set.postgres.metadata[0].name
}

output "secret_name" {
  description = "PostgreSQL secret name"
  value       = kubernetes_secret.postgres.metadata[0].name
}

output "pvc_name" {
  description = "PostgreSQL PVC name"
  value       = kubernetes_persistent_volume_claim.postgres.metadata[0].name
}
