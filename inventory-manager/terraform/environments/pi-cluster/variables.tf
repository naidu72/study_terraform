<<<<<<< HEAD
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
=======
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "/home/naidu/.kube/config"
>>>>>>> 392b57c (fix: restore variables.tf with proper variable definitions)
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "pi-k3s"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "inventory-manager"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "inventory-manager"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "pi-cluster"
}

variable "backend_image" {
  description = "Backend Docker image"
  type        = string
  default     = "ghcr.io/naidu72/inventory-backend:latest"
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 1
}

variable "frontend_image" {
  description = "Frontend Docker image"
  type        = string
  default     = "ghcr.io/naidu72/inventory-frontend:latest"
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 1
}

variable "enable_frontend_ingress" {
  description = "Enable frontend ingress"
  type        = bool
  default     = true
}

variable "frontend_ingress_host" {
  description = "Frontend ingress hostname"
  type        = string
  default     = "inventory-pi.naidu72.info"
}

variable "frontend_tls_secret_name" {
  description = "Frontend TLS secret name"
  type        = string
  default     = "naidu72-wildcard-tls"
}

variable "postgres_image" {
  description = "PostgreSQL image"
  type        = string
  default     = "postgres:15-alpine"
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "5Gi"
}

variable "postgres_storage_class" {
  description = "PostgreSQL storage class"
  type        = string
  default     = "local-path"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "inventory_user"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "postgres_database" {
  description = "PostgreSQL database"
  type        = string
  default     = "inventory_db"
}

variable "redis_image" {
  description = "Redis image"
  type        = string
  default     = "redis:7-alpine"
}

variable "redis_storage_size" {
  description = "Redis storage size"
  type        = string
  default     = "2Gi"
}

variable "redis_storage_class" {
  description = "Redis storage class"
  type        = string
  default     = "local-path"
}

variable "enable_ingress" {
  description = "Enable backend ingress"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Backend ingress hostname"
  type        = string
  default     = "inventory-api.naidu72.info"
}

variable "ingress_class" {
  description = "Ingress class"
  type        = string
  default     = "cloudflare-tunnel"
}

variable "enable_tls" {
  description = "Enable TLS"
  type        = bool
  default     = true
}

variable "backend_cpu_request" {
  description = "Backend CPU request"
  type        = string
  default     = "100m"
}

variable "backend_cpu_limit" {
  description = "Backend CPU limit"
  type        = string
  default     = "500m"
}

variable "backend_memory_request" {
  description = "Backend memory request"
  type        = string
  default     = "128Mi"
}

variable "backend_memory_limit" {
  description = "Backend memory limit"
  type        = string
  default     = "512Mi"
}

variable "common_labels" {
  description = "Common labels"
  type        = map(string)
  default = {
    "app.kubernetes.io/name"       = "inventory-manager"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = "pi-cluster"
    "architecture"                 = "arm64"
  }
}

variable "ghcr_username" {
  description = "GHCR username"
  type        = string
  default     = "naidu72"
}

variable "ghcr_token" {
  description = "GHCR token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = ""
}
