resource "kubernetes_namespace_v1" "ns_terraform" {
    metadata {
      name = "terraform"
      
    }
  lifecycle {
    ignore_changes = [metadata[0].labels]   # Terraform never touches labels
  }
}
