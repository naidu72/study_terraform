output "ghcr_secret_name" {
  description = "Name of the GHCR secret"
  value       = kubernetes_secret.ghcr.metadata[0].name
}
