variable "env" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}
# variable "docker_host" {  ## we have moved from hard coded logic to locals.tf L22 to L33 this will pick based on the workspace
#   type        = string
#   description = "dokcer engine"
#   #default     = "ssh://naidu@pi"
#   default     = "unix:///mnt/wsl/shared-docker/docker.sock"
# }
variable "project" {
  type        = string
  description = "Project name — used in all resource names"
  default     = "homelab"
}

variable "nginx_version" {
  type        = string
  description = "Nginx image tag"
  default     = "stable"
}

variable "nginx_port" {
  type        = number
  description = "Host port for nginx"
  default     = 8080

  validation {
    condition     = var.nginx_port > 1024 && var.nginx_port < 65535
    error_message = "nginx_port must be an unprivileged port (1024–65535)."
  }
}

variable "postgres_version" {
  type    = string
  default = "15"
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  #default = "naidu123"
  sensitive = true   # never printed in plan output or logs
}
