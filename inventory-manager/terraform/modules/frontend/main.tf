# ConfigMap for nginx configuration (if needed for custom config)
resource "kubernetes_config_map" "frontend" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    "BACKEND_URL" = var.backend_service_url
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels    = merge(var.labels, {
      app       = var.app_name
      component = "frontend"
      tier      = "presentation"
    })
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app       = var.app_name
        component = "frontend"
      }
    }

    template {
      metadata {
        labels = merge(var.labels, {
          app       = var.app_name
          component = "frontend"
          tier      = "presentation"
        })
      }

      spec {
        # Image pull secrets for private registries
        image_pull_secrets {
          name = var.ghcr_secret_name
        }

        container {
          name              = "frontend"
          image             = var.image
          image_pull_policy = "Always"

          port {
            container_port = 80
            name          = "http"
            protocol      = "TCP"
          }

          # Environment variables  
          env {
            name  = "BACKEND_URL"
            value = var.backend_service_url
          }

          # Resource limits
          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          # Liveness probe
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Readiness probe
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        # Restart policy
        restart_policy = "Always"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
        max_surge       = "1"
      }
    }
  }
}

# Frontend Service
resource "kubernetes_service" "frontend" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = var.namespace
    labels    = merge(var.labels, {
      app       = var.app_name
      component = "frontend"
    })
  }

  spec {
    selector = {
      app       = var.app_name
      component = "frontend"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Ingress for external access
resource "kubernetes_ingress_v1" "frontend" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = var.namespace
    labels    = var.labels

    annotations = {
      "strrl.dev/cloudflare-tunnel-enabled" = "true"
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    # No TLS configuration needed - Cloudflare Tunnel handles it

    rule {
      host = var.ingress_host

      http {
        # Root path - serve frontend (handles API proxying internally via Nginx)
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Horizontal Pod Autoscaler (optional, for production)
resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend" {
  metadata {
    name      = "${var.app_name}-hpa"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.frontend.metadata[0].name
    }

    min_replicas = var.replicas
    max_replicas = var.replicas * 3

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
