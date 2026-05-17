output "name_space" {
    value = kubernetes_namespace_v1.this.metadata[0].name
}
output "current_workspace" {
    value = terraform.workspace
  
}