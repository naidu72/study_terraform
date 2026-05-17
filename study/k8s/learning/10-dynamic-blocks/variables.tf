variable "namespaces" {
  type = map(object({
    team        = string
    environment = string
  }))
  default = {
    "lesson10-app" = {
      team        = "backend"
      environment = "dev"
    }
    "lesson10-monitoring" = {
      team        = "platform"
      environment = "dev"
    }
    "lesson10-data" = {
      team        = "data"
      environment = "staging"
    }
  }
}
variable "role_rules" {
  type = list(object({
    api_groups = list(string)
    resources  = list(string)
    verbs      = list(string)
  }))
  default = [
    {
      api_groups = [""]
      resources  = ["pods"]
      verbs      = ["get", "list", "watch"]
    },
    {
      api_groups = [""]
      resources  = ["services"]
      verbs      = ["get", "list"]
    },
    {
      api_groups = ["apps"]
      resources  = ["deployments"]
      verbs      = ["get", "list", "watch", "update"]
    }
  ]
}
