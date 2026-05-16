resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = {
      team        = var.team
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
