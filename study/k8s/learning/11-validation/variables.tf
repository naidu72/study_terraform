variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "namespace_name" {
  type        = string
  description = "Kubernetes namespace name"

  validation {
    condition     = length(var.namespace_name) >= 3 && length(var.namespace_name) <= 63
    error_message = "namespace_name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace_name))
    error_message = "namespace_name must only contain lowercase letters, numbers, and hyphens."
  }
}

variable "replica_count" {
  type        = number
  description = "Number of replicas"

  validation {
    condition     = var.replica_count >= 1 && var.replica_count <= 10
    error_message = "replica_count must be between 1 and 10."
  }
}
