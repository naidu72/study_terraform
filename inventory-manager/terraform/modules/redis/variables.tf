variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "image" {
  description = "Redis image"
  type        = string
  default     = "redis:7-alpine"
}

variable "storage_size" {
  description = "Storage size for PVC"
  type        = string
  default     = "2Gi"
}

variable "storage_class" {
  description = "Storage class name"
  type        = string
  default     = "local-path"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "256Mi"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
