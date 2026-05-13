resource "kubernetes_namespace_v1" "terraform_ns" {
    metadata {
      name = local.namespce_name
      labels = local.common_labels
    }
  
}