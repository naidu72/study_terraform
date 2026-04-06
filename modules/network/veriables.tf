variable "name" {
  type        = string
  description = "Docker network name"
}

variable "driver" {
  type        = string
  description = "Docker network driver"
  default     = "bridge"

  validation {
    condition     = contains(["bridge", "overlay", "host"], var.driver)
    error_message = "driver must be bridge, overlay, or host."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels to stamp on the network resource"
  default     = {}
}
