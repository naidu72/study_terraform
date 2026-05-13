variable "namespace_name" {
description = "The name of the k8s namespace to create"
type = string
default = "terraform"
}
variable "replica_count" {
    type = number
    default = 2
}
variable "enable_labels" {
    type = bool
    default = true
  
}
variable "team_labels" {
    type = map(string)
    default = {
      team = "platform"
      environment = "dev"
    } 
}
variable "namespace_config" {
  type = object({
    name        = string
    team        = string
    environment = string
    replicas    = number
  })
  default = {
    name        = "my-configured-namespace"
    team        = "platform"
    environment = "dev"
    replicas    = 1
  }
}