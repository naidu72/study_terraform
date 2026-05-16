output "name" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}

output "uid" {
  value = kubernetes_namespace_v1.this.metadata[0].uid
}
output "labels" {
  value = kubernetes_namespace_v1.this.metadata[0].labels
  
}