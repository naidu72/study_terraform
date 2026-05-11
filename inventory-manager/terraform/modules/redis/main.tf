# Redis Module - Deploys Redis with persistent storage

# PersistentVolumeClaim for Redis data
resource "kubernetes_persistent_volume_claim" "redis" {
  metadata {
    name      = "${var.app_name}-redis-pvc"
    namespace = var.namespace
    labels    = var.labels
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }

  wait_until_bound = false
}

# Deployment for Redis
resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "${var.app_name}-redis"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "cache" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app"       = "${var.app_name}-redis"
        "component" = "cache"
      }
    }

    template {
      metadata {
        labels = {
          "app"       = "${var.app_name}-redis"
          "component" = "cache"
        }
      }

      spec {
        container {
          name  = "redis"
          image = var.image

          port {
            container_port = 6379
            name           = "redis"
          }

          command = [
            "redis-server",
            "--appendonly",
            "yes",
            "--save",
            "60",
            "1"
          ]

          volume_mount {
            name       = "redis-data"
            mount_path = "/data"
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
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["redis-cli", "ping"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "redis-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for Redis
resource "kubernetes_service" "redis" {
  metadata {
    name      = "${var.app_name}-redis"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "cache" })
  }

  spec {
    selector = {
      "app"       = "${var.app_name}-redis"
      "component" = "cache"
    }

    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
