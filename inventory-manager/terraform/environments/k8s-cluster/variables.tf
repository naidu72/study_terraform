# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/local"
}

variable "kubeconfig_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "kind-k8s-kind"
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

variable "backend_image" {
  description = "Backend container image"
  type        = string
  default     = "ghcr.io/naidu72/inventory-backend"
}

variable "backend_tag" {
  description = "Backend container image tag"
  type        = string
  default     = "latest"
}

variable "replicas" {
  description = "Number of backend replicas"
  type        = number
  default     = 3
}

# PostgreSQL Configuration
variable "postgres_image" {
  description = "PostgreSQL container image"
  type        = string
  default     = "postgres:16-alpine"
}

variable "postgres_storage_size" {
  description = "PostgreSQL storage size"
  type        = string
  default     = "10Gi"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "inventory_user"
}

variable "postgres_password" {
  description = "PostgreSQL password (sensitive)"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "inventory_db"
}

# Redis Configuration
variable "redis_image" {
  description = "Redis container image"
  type        = string
  default     = "redis:7-alpine"
}

variable "redis_storage_size" {
  description = "Redis storage size"
  type        = string
  default     = "5Gi"
}

# Security
variable "jwt_secret_key" {
  description = "JWT secret key for authentication"
  type        = string
  sensitive   = true
}

# Resource Limits - Backend
variable "backend_cpu_request" {
  description = "Backend CPU request"
  type        = string
  default     = "500m"
}

variable "backend_memory_request" {
  description = "Backend memory request"
  type        = string
  default     = "512Mi"
}

variable "backend_cpu_limit" {
  description = "Backend CPU limit"
  type        = string
  default     = "1000m"
}

variable "backend_memory_limit" {
  description = "Backend memory limit"
  type        = string
  default     = "1Gi"
}

# Resource Limits - PostgreSQL
variable "postgres_cpu_request" {
  description = "PostgreSQL CPU request"
  type        = string
  default     = "500m"
}

variable "postgres_memory_request" {
  description = "PostgreSQL memory request"
  type        = string
  default     = "1Gi"
}

variable "postgres_cpu_limit" {
  description = "PostgreSQL CPU limit"
  type        = string
  default     = "1000m"
}

variable "postgres_memory_limit" {
  description = "PostgreSQL memory limit"
  type        = string
  default     = "2Gi"
}

# Resource Limits - Redis
variable "redis_cpu_request" {
  description = "Redis CPU request"
  type        = string
  default     = "250m"
}

variable "redis_memory_request" {
  description = "Redis memory request"
  type        = string
  default     = "512Mi"
}

variable "redis_cpu_limit" {
  description = "Redis CPU limit"
  type        = string
  default     = "500m"
}

variable "redis_memory_limit" {
  description = "Redis memory limit"
  type        = string
  default     = "1Gi"
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable ingress resource"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = "inventory-manager-k8s.local"
}

variable "tls_enabled" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    "project"     = "inventory-manager"
    "managed-by"  = "terraform"
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
}
