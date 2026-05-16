resource "kubernetes_namespace_v1" "test" {
    metadata {
      name = "lesson6"
      labels = {
        env = "dev"
        createdby = var.secret_token
      }
    }
  
}
