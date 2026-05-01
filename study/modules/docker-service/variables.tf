# ── Required inputs (no default = caller must provide) ────────
variable "name" {
  type        = string
  description = "Container name. Used as the Docker container name."
}

variable "image" {
  type        = string
  description = "Full Docker image reference e.g. nginx:stable"
}

variable "internal_port" {
  type        = number
  description = "Port the process listens on inside the container"
}

variable "external_port" {
  type        = number
  description = "Port exposed on the host"

  validation {
    condition     = var.external_port > 1024 && var.external_port < 65535
    error_message = "external_port must be an unprivileged port (1025-65534)."
  }
}

variable "network_name" {
  type        = string
  description = "Docker network to attach this container to"
}

# ── Optional inputs (have defaults, caller can override) ───────
variable "env_vars" {
  type        = map(string)
  description = "Environment variables injected into the container"
  default     = {}
}

variable "env" {
  type        = string
  description = "Deployment environment: dev, staging, prod"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

variable "protected" {
  type        = bool
  description = "When true, prevent_destroy is active. Set for prod containers."
  default     = false
}
