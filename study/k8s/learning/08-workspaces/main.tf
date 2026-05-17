resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "lesson8-${terraform.workspace}"
      labels = {
        environment = terraform.workspace
        manged_by = "trraform"
      }
    }
  
}