variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "image" {
  description = "PostgreSQL image"
  type        = string
  default     = "postgres:15-alpine"
}

variable "storage_size" {
  description = "Storage size for PVC"
  type        = string
  default     = "5Gi"
}

variable "storage_class" {
  description = "Storage class name"
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
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "inventory_db"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
