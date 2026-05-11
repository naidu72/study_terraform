# Backend Application Module - Deploys the FastAPI backend application

# Secret for application configuration
resource "kubernetes_secret" "backend" {
  metadata {
    name      = "${var.app_name}-backend-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    DATABASE_URL = "postgresql://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:${var.postgres_port}/${var.postgres_database}"
    REDIS_URL    = "redis://${var.redis_host}:${var.redis_port}/0"
    SECRET_KEY   = var.jwt_secret_key
  }

  type = "Opaque"
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "backend" {
  metadata {
    name      = "${var.app_name}-backend-config"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    APP_NAME                  = "Inventory Manager API"
    APP_VERSION               = "1.0.0"
    DEBUG                     = "False"
    ALGORITHM                 = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = "30"
    LOW_STOCK_THRESHOLD       = "10"
    REDIS_CACHE_TTL           = "300"
  }
}

# Deployment for Backend
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${var.app_name}-backend"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "backend" })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app"       = "${var.app_name}-backend"
        "component" = "backend"
      }
    }

    template {
      metadata {
        labels = {
          "app"       = "${var.app_name}-backend"
          "component" = "backend"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8000"
          "prometheus.io/path"   = "/health"
        }
      }

      spec {
        container {
          name              = "backend"
          image             = var.image
          image_pull_policy = "Always"

          port {
            container_port = 8000
            name           = "http"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.backend.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 12
          }
        }

        # Init container to wait for dependencies
        init_container {
          name  = "wait-for-postgres"
          image = "busybox:1.35"

          command = [
            "sh",
            "-c",
            "until nc -z ${var.postgres_host} ${var.postgres_port}; do echo waiting for postgres; sleep 2; done"
          ]
        }

        init_container {
          name  = "wait-for-redis"
          image = "busybox:1.35"

          command = [
            "sh",
            "-c",
            "until nc -z ${var.redis_host} ${var.redis_port}; do echo waiting for redis; sleep 2; done"
          ]
        }

        # Image pull secrets for private registries
        image_pull_secrets {
          name = var.ghcr_secret_name
        }
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }
  }
}

# Service for Backend
resource "kubernetes_service" "backend" {
  metadata {
    name      = "${var.app_name}-backend"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "backend" })
  }

  spec {
    selector = {
      "app"       = "${var.app_name}-backend"
      "component" = "backend"
    }

    port {
      name        = "http"
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Optional: Ingress for external access
resource "kubernetes_ingress_v1" "backend" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.app_name}-backend"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "backend" })

    annotations = {
      "kubernetes.io/ingress.class"                = var.ingress_class
      "cert-manager.io/cluster-issuer"             = var.enable_tls ? "letsencrypt-prod" : ""
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = "${var.app_name}-backend-tls"
      }
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/api(/|$)(.*)"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}

# Job to initialize database
resource "kubernetes_job" "init_db" {
  metadata {
    name      = "${var.app_name}-init-db"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "init" })
  }

  spec {
    template {
      metadata {
        labels = {
          "app"       = "${var.app_name}-init"
          "component" = "init"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name              = "init-db"
          image             = var.image
          image_pull_policy = "Always"

          command = ["python", "init_db.py"]

          env_from {
            secret_ref {
              name = kubernetes_secret.backend.metadata[0].name
            }
          }
        }

        init_container {
          name  = "wait-for-postgres"
          image = "busybox:1.35"

          command = [
            "sh",
            "-c",
            "until nc -z ${var.postgres_host} ${var.postgres_port}; do echo waiting for postgres; sleep 2; done; sleep 10"
          ]
        }

        # Image pull secrets for private registries
        image_pull_secrets {
          name = var.ghcr_secret_name
        }
      }
    }

    backoff_limit = 4
  }

  wait_for_completion = false

  depends_on = [
    kubernetes_deployment.backend
  ]
}
