resource "kubernetes_config_map_v1" "namespace_registry" {
  metadata {
    name      = "namespace-registry"
    namespace = "default01"
  }

  data = {
    for name, config in var.namespaces :
    name => "${config.team}/${config.environment}"
  }
}
resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces

  metadata {
    name = each.key
    labels = {
      team        = each.value.team
      environment = each.value.environment
    }
  }
}

resource "kubernetes_role_v1" "this" {
  metadata {
    name      = "lesson10-role"
    namespace = "lesson10-app"
  }

  dynamic "rule" {
    for_each = var.role_rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}
