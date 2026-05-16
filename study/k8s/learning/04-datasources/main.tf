data "kubernetes_namespace_v1" "kube-system" {
    metadata {
      name = "kube-system"
    }
}
resource "kubernetes_namespace_v1" "this" {
    metadata {
      name = "lesson4-namespace"
      labels = {
        copied_from = data.kubernetes_namespace_v1.kube-system.metadata[0].name
      }
    }
  
}
data "kubernetes_endpoints_v1" "ep" {
  metadata {
    name = "pi-host-ssh"
    namespace = "default"
  }
  
}