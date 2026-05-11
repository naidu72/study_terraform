output "cluster_type" {
  description = "Cluster type"
  value       = "k8s-k8s (amd64)"
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = module.inventory_manager.namespace_name
}

output "postgresql_service" {
  description = "PostgreSQL service URL"
  value       = module.inventory_manager.postgresql_service_name
}

output "redis_service" {
  description = "Redis service URL"
  value       = module.inventory_manager.redis_service_name
}

output "backend_service" {
  description = "Backend service URL"
  value       = module.inventory_manager.backend_service_name
}

output "ingress_host" {
  description = "Ingress host (if enabled)"
  value       = var.enable_ingress ? var.ingress_host : "N/A"
}

output "application_info" {
  description = "Application information"
  value = {
    app_name  = module.inventory_manager.app_name
    replicas  = module.inventory_manager.replicas
    image     = "${module.inventory_manager.backend_image}:${module.inventory_manager.backend_tag}"
  }
}

output "access_instructions" {
  description = "Instructions to access the application"
  value = <<-EOT
    ╔════════════════════════════════════════════════════════════════╗
    ║       🎉 Inventory Manager - K8S Cluster Deployment 🎉        ║
    ╚════════════════════════════════════════════════════════════════╝
    
    📍 Cluster: k8s-k8s (amd64)
    📦 Namespace: ${module.inventory_manager.namespace_name}
    🚀 Replicas: ${module.inventory_manager.replicas}
    
    🔍 Check Deployment Status:
       kubectl get all -n ${module.inventory_manager.namespace_name}
    
    🔌 Access the API (port-forward):
       kubectl port-forward -n ${module.inventory_manager.namespace_name} svc/${module.inventory_manager.backend_service_name} 8000:8000
       Then visit: http://localhost:8000/docs
    
    ${var.enable_ingress ? "🌐 Ingress URL: http://${var.ingress_host}/docs" : ""}
    
    📊 View Logs:
       kubectl logs -n ${module.inventory_manager.namespace_name} -l app=${module.inventory_manager.app_name}
    
    🔧 Database Connection:
       postgresql://${var.postgres_user}@${module.inventory_manager.postgresql_service_name}.${module.inventory_manager.namespace_name}.svc.cluster.local:5432/${var.postgres_db}
    
    💾 Redis Connection:
       redis://${module.inventory_manager.redis_service_name}.${module.inventory_manager.namespace_name}.svc.cluster.local:6379
    
    ═══════════════════════════════════════════════════════════════════
  EOT
}
