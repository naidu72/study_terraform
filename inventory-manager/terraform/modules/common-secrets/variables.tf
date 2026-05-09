variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "ghcr_username" {
  description = "GitHub Container Registry username"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Container Registry token"
  type        = string
  sensitive   = true
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}
