resource "kubernetes_namespace_v1" "ns_terraform" {
    metadata {
      name = "terraform"
      
    }
  
}
