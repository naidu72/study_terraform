variable "name" {
  description = "Namespace name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "labels" {
  description = "Labels to apply to namespace"
  type        = map(string)
  default     = {}
}

# Resource Quota
variable "enable_resource_quota" {
  description = "Enable resource quota for namespace"
  type        = bool
  default     = false
}

variable "quota_cpu_requests" {
  description = "Total CPU requests quota"
  type        = string
  default     = "4"
}

variable "quota_memory_requests" {
  description = "Total memory requests quota"
  type        = string
  default     = "8Gi"
}

variable "quota_cpu_limits" {
  description = "Total CPU limits quota"
  type        = string
  default     = "8"
}

variable "quota_memory_limits" {
  description = "Total memory limits quota"
  type        = string
  default     = "16Gi"
}

variable "quota_pods" {
  description = "Maximum number of pods"
  type        = string
  default     = "20"
}

# Limit Range
variable "enable_limit_range" {
  description = "Enable limit range for namespace"
  type        = bool
  default     = false
}

variable "default_cpu_request" {
  description = "Default CPU request for containers"
  type        = string
  default     = "100m"
}

variable "default_cpu_limit" {
  description = "Default CPU limit for containers"
  type        = string
  default     = "500m"
}

variable "default_memory_request" {
  description = "Default memory request for containers"
  type        = string
  default     = "128Mi"
}

variable "default_memory_limit" {
  description = "Default memory limit for containers"
  type        = string
  default     = "512Mi"
}
