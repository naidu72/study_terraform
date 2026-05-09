# Common Secrets Module - Shared secrets across all application components

# Secret for GHCR image pull (shared by all components)
resource "kubernetes_secret" "ghcr" {
  metadata {
    name      = "ghcr-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.ghcr_username
          password = var.ghcr_token
          auth     = base64encode("${var.ghcr_username}:${var.ghcr_token}")
        }
      }
    })
  }
}
