# Namespace Module - Creates and manages Kubernetes namespace

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name

    labels = merge(
      var.labels,
      {
        "environment" = var.environment
        "managed-by"  = "terraform"
      }
    )

    annotations = {
      "description" = "Namespace for Inventory Manager application"
      "created-by"  = "terraform"
    }
  }
}

# Optional: Resource Quota
resource "kubernetes_resource_quota" "this" {
  count = var.enable_resource_quota ? 1 : 0

  metadata {
    name      = "${var.name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.quota_cpu_requests
      "requests.memory" = var.quota_memory_requests
      "limits.cpu"      = var.quota_cpu_limits
      "limits.memory"   = var.quota_memory_limits
      "pods"            = var.quota_pods
    }
  }
}

# Optional: Limit Range
resource "kubernetes_limit_range" "this" {
  count = var.enable_limit_range ? 1 : 0

  metadata {
    name      = "${var.name}-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  spec {
    limit {
      type = "Container"

      default = {
        cpu    = var.default_cpu_limit
        memory = var.default_memory_limit
      }

      default_request = {
        cpu    = var.default_cpu_request
        memory = var.default_memory_request
      }
    }
  }
}
