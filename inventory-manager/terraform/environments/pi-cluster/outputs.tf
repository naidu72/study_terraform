# Outputs from Pi Cluster deployment

output "namespace" {
  description = "Deployed namespace"
  value       = module.inventory_manager.namespace
}

output "backend_service_url" {
  description = "Backend service URL"
  value       = module.inventory_manager.backend_service_url
}

output "postgres_service" {
  description = "PostgreSQL service"
  value       = module.inventory_manager.postgres_service
}

output "redis_service" {
  description = "Redis service"
  value       = module.inventory_manager.redis_service
}

output "application_info" {
  description = "Application information"
  value       = module.inventory_manager.application_info
}

output "access_instructions" {
  description = "How to access the application"
  value = <<-EOT
    
    Application deployed to Pi cluster!
    
    Namespace: ${module.inventory_manager.namespace}
    Backend Service: ${module.inventory_manager.backend_service_url}
    
    To access the API:
    1. Port-forward the backend service:
       kubectl port-forward -n ${module.inventory_manager.namespace} svc/${module.inventory_manager.backend_service} 8000:8000
    
    2. Access the API:
       http://localhost:8000/docs
    
    3. Check pod status:
       kubectl get pods -n ${module.inventory_manager.namespace}
    
    4. View logs:
       kubectl logs -n ${module.inventory_manager.namespace} -l app=inventory-manager-backend
    
  EOT
}
