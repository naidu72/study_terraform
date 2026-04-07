resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      managed-by  = "terraform"
      environment = var.env
    }
  }
}
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  data = {
    APP_ENV      = var.env
    LOG_LEVEL    = "info"
    DATABASE_URL = "postgresql://localhost:5432/appdb"
  }
}
resource "kubernetes_secret" "db_creds" {
  metadata {
    name      = "db-creds"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  # type defaults to Opaque
  data = {
    username = var.db_user
    password = var.db_password   # mark sensitive = true in variable
  }
}
# Terraform base64-encodes values automatically —
# you pass plaintext, K8s stores it encoded
