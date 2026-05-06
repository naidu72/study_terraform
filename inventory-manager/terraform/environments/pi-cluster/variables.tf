# Pi Cluster Configuration Variables
# Inherits from main module variables

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/pi-cluster"
}

variable "kubeconfig_context" {
  description = "Kubernetes context for pi-k8s cluster"
  type        = string
  default     = "pi-k8s"
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

variable "backend_image" {
  description = "Backend Docker image (multi-arch)"
  type        = string
  default     = "ghcr.io/naidu72/inventory-backend:latest"
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
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
  default     = "inventory_pass"
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

variable "jwt_secret_key" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
  default     = "change-this-in-production-use-vault"
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
  default     = "256Mi"
}

variable "backend_memory_limit" {
  description = "Backend memory limit"
  type        = string
  default     = "512Mi"
}

variable "enable_ingress" {
  description = "Enable ingress"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = "inventory-pi.local"
}

variable "ingress_class" {
  description = "Ingress class"
  type        = string
  default     = "nginx"
}

variable "enable_tls" {
  description = "Enable TLS"
  type        = bool
  default     = false
}

# Frontend Configuration
variable "frontend_image" {
  description = "Frontend Docker image (multi-arch)"
  type        = string
  default     = "ghcr.io/naidu72/inventory-frontend:latest"
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
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
  default     = "inventory-frontend-pi-tls"
}

variable "common_labels" {
  description = "Common labels"
  type        = map(string)
  default = {
    "app.kubernetes.io/name"       = "inventory-manager"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

# GHCR Credentials
variable "ghcr_username" {
  description = "GitHub Container Registry username"
  type        = string
  default     = "naidu72"
}

variable "ghcr_token" {
  description = "GitHub Container Registry token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "pi-cluster"
}
