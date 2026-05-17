resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "lesson9-remote-state"
      labels = {
        manged_by = "terraform"
      }
    }
  
}