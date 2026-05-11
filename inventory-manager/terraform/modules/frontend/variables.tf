variable "namespace" {
  description = "Kubernetes namespace for frontend deployment"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "inventory-manager-frontend"
}

variable "image" {
  description = "Docker image for frontend"
  type        = string
  default     = "ghcr.io/naidu72/inventory-frontend:latest"
}

variable "replicas" {
  description = "Number of frontend replicas"
  type        = number
  default     = 2
}

variable "backend_service_url" {
  description = "Backend API service URL (internal)"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# Ingress configuration
variable "enable_ingress" {
  description = "Enable ingress for external access"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = "inventory.naidu72.info"
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "cloudflare-tunnel"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = true
}

variable "tls_secret_name" {
  description = "Name of TLS secret for ingress"
  type        = string
  default     = "inventory-frontend-tls"
}

# GHCR credentials for image pull
variable "ghcr_username" {
  description = "GHCR username"
  type        = string
  default     = ""
}

variable "ghcr_token" {
  description = "GHCR token/password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ghcr_secret_name" {
  description = "Name of the GHCR Kubernetes secret"
  type        = string
  default     = "ghcr-secret"
}

variable "backend_service_name" {
  description = "Name of the backend service for Ingress routing"
  type        = string
  default     = "inventory-manager-backend"
}
