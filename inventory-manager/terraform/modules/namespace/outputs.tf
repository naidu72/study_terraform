output "name" {
  description = "Namespace name"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "id" {
  description = "Namespace ID"
  value       = kubernetes_namespace.this.id
}

output "labels" {
  description = "Namespace labels"
  value       = kubernetes_namespace.this.metadata[0].labels
}
