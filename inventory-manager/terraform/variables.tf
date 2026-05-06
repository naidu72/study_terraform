# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

# Application Configuration
variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "inventory-manager"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "inventory-manager"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Image Configuration
variable "backend_image" {
  description = "Docker image for backend application"
  type        = string
  default     = "ghcr.io/naidu72/inventory-backend:latest"
}

variable "backend_replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 2
}

# PostgreSQL Configuration
variable "postgres_image" {
  description = "PostgreSQL image"
  type        = string
  default     = "postgres:15-alpine"
}

variable "postgres_storage_size" {
  description = "PostgreSQL PVC storage size"
  type        = string
  default     = "5Gi"
}

variable "postgres_storage_class" {
  description = "Storage class for PostgreSQL PVC"
  type        = string
  default     = "local-path"
}

# Redis Configuration
variable "redis_image" {
  description = "Redis image"
  type        = string
  default     = "redis:7-alpine"
}

variable "redis_storage_size" {
  description = "Redis PVC storage size"
  type        = string
  default     = "2Gi"
}

variable "redis_storage_class" {
  description = "Storage class for Redis PVC"
  type        = string
  default     = "local-path"
}

# Secrets Configuration
variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
  default     = "inventory_pass"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "inventory_user"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "inventory_db"
}

variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
  default     = "change-this-secret-key-in-production"
}

# Resource Limits
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

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable ingress for external access"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = "inventory.local"
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

# Frontend Configuration
variable "frontend_image" {
  description = "Docker image for frontend"
  type        = string
  default     = "ghcr.io/naidu72/inventory-frontend:latest"
}

variable "frontend_replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "enable_frontend_ingress" {
  description = "Enable ingress for frontend"
  type        = bool
  default     = true
}

variable "frontend_ingress_host" {
  description = "Frontend ingress hostname"
  type        = string
  default     = "inventory.naidu72.info"
}

variable "frontend_tls_secret_name" {
  description = "TLS secret name for frontend ingress"
  type        = string
  default     = "inventory-frontend-tls"
}

# Labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
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
