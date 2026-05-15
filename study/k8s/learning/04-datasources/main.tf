data "kubernetes_namespace_v1" "kube-system" {
    metadata {
      name = "kube-system"
    }
}
resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "lesson4-namespace"
      labels = {
        copied_from = data.kubernetes_namespace_v1.kube-sysyem.metadata[0].name
      }
    }
  
}
