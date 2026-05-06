output "deployment_name" {
  description = "Name of the frontend deployment"
  value       = kubernetes_deployment.frontend.metadata[0].name
}

output "service_name" {
  description = "Name of the frontend service"
  value       = kubernetes_service.frontend.metadata[0].name
}

output "service_url" {
  description = "Internal service URL"
  value       = "http://${kubernetes_service.frontend.metadata[0].name}.${var.namespace}.svc.cluster.local"
}

output "ingress_host" {
  description = "Ingress hostname"
  value       = var.enable_ingress ? var.ingress_host : ""
}

output "ingress_url" {
  description = "Public URL (if ingress enabled)"
  value       = var.enable_ingress ? "https://${var.ingress_host}" : ""
}

output "replicas" {
  description = "Number of frontend replicas"
  value       = var.replicas
}
