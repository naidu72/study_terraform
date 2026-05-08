# Pi Cluster Environment Variables
# kubeconfig is written to ~/.kube/config by the CI/CD pipeline from Vault

kubeconfig_path    = "/home/naidu/.kube/config"
kubeconfig_context = "pi-k3s"

namespace  = "inventory-manager"
app_name   = "inventory-manager"
environment = "pi-cluster"

# Backend
backend_image    = "ghcr.io/naidu72/inventory-backend:latest"
backend_replicas = 1

# Frontend
frontend_image           = "ghcr.io/naidu72/inventory-frontend:latest"
frontend_replicas        = 1
enable_frontend_ingress  = true
frontend_ingress_host    = "inventory-pi.naidu72.info"
frontend_tls_secret_name = "naidu72-wildcard-tls"

# PostgreSQL
postgres_image         = "postgres:15-alpine"
postgres_storage_size  = "5Gi"
postgres_storage_class = "local-path"
postgres_user          = "inventory_user"
postgres_database      = "inventory_db"

## Redis
redis_image         = "redis:7-alpine"
redis_storage_size  = "2Gi"
redis_storage_class = "local-path"

# Ingress
enable_ingress = true
ingress_host   = "inventory-api.naidu72.info"
ingress_class  = "cloudflare-tunnel"
enable_tls     = true

# Resource limits (Pi5 friendly)
backend_cpu_request    = "100m"
backend_cpu_limit      = "500m"
backend_memory_request = "128Mi"
backend_memory_limit   = "512Mi"

# Labels
common_labels = {
  "app.kubernetes.io/name"       = "inventory-manager"
  "app.kubernetes.io/managed-by" = "terraform"
  "environment"                  = "pi-cluster"
  "architecture"                 = "arm64"
}

