resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "lesson5-green"
    }
    lifecycle {
      create_before_destroy = true
    }
}