variable "env" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

variable "project" {
  type    = string
  default = "homelab"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type = string
  #default = "naidu123"
  sensitive = true # never printed in plan output or logs
}
