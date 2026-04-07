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

# The services map — this drives the for_each
variable "services" {
  type = map(object({
    image         = string
    internal_port = number
    external_port = number
    env_vars      = optional(map(string), {})
  }))
  description = "Map of services to deploy. Key = service name."
}