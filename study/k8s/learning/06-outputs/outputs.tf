output "name_space" {
    description = "name of the namespace"
    value = kubernetes_namespace_v1.test.metadata[0].name
  
}
output "labels" {
    description = "labels of namespace"
    value = kubernetes_namespace_v1.test.metadata[0].labels
  
}
output "uid" {
    description = "uid of the namespace"
    value = kubernetes_namespace_v1.test.metadata[0].uid
  
}
output "fake_secret" {
  description = "Simulating a sensitive value"
  value       = "super-secret-token-123"
  sensitive   = true
}
output "token_length" {
  value = length(var.secret_token)
  sensitive = true
}
