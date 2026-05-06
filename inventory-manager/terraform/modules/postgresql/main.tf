# PostgreSQL Module - Deploys PostgreSQL as a StatefulSet with persistent storage

# Secret for PostgreSQL credentials
resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres-secret"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password
    POSTGRES_DB       = var.postgres_database
  }

  type = "Opaque"
}

# ConfigMap for PostgreSQL initialization
resource "kubernetes_config_map" "postgres_init" {
  metadata {
    name      = "${var.app_name}-postgres-init"
    namespace = var.namespace
    labels    = var.labels
  }

  data = {
    "init.sql" = <<-EOT
      -- Database initialization script
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      
      -- Grant privileges
      GRANT ALL PRIVILEGES ON DATABASE ${var.postgres_database} TO ${var.postgres_user};
      
      -- Create schema if needed
      CREATE SCHEMA IF NOT EXISTS public;
      GRANT ALL ON SCHEMA public TO ${var.postgres_user};
    EOT
  }
}

# PersistentVolumeClaim for PostgreSQL data
resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres-pvc"
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

# StatefulSet for PostgreSQL
resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "database" })
  }

  spec {
    service_name = "${var.app_name}-postgres"
    replicas     = 1

    selector {
      match_labels = {
        "app"       = "${var.app_name}-postgres"
        "component" = "database"
      }
    }

    template {
      metadata {
        labels = {
          "app"       = "${var.app_name}-postgres"
          "component" = "database"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = var.image

          port {
            container_port = 5432
            name           = "postgres"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata[0].name
            }
          }

          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          volume_mount {
            name       = "init-scripts"
            mount_path = "/docker-entrypoint-initdb.d"
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
              command = ["pg_isready", "-U", var.postgres_user]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }

        volume {
          name = "init-scripts"
          config_map {
            name = kubernetes_config_map.postgres_init.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for PostgreSQL
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "${var.app_name}-postgres"
    namespace = var.namespace
    labels    = merge(var.labels, { "component" = "database" })
  }

  spec {
    selector = {
      "app"       = "${var.app_name}-postgres"
      "component" = "database"
    }

    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
