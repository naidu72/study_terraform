# Pi Cluster Environment Configuration
# Uses the pi-k8s context (arm64 architecture)

terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Local backend - MinIO has signature compatibility issues
  # State will be stored locally in terraform.tfstate
  # Can migrate to MinIO later with: terraform init -migrate-state
}

# Kubernetes Provider - Using pi-k8s context
provider "kubernetes" {
  # This will use the kubeconfig configured for pi-k8s
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# Use the main module
module "inventory_manager" {
  source = "../.."

  # Kubernetes Configuration
  namespace          = var.namespace
  kubeconfig_path    = var.kubeconfig_path
  kubeconfig_context = var.kubeconfig_context

  # Application Configuration
  app_name         = var.app_name
  environment      = "pi-cluster"
  backend_image    = var.backend_image
  backend_replicas = var.backend_replicas

  # PostgreSQL Configuration
  postgres_image        = var.postgres_image
  postgres_storage_size = var.postgres_storage_size
  postgres_storage_class = var.postgres_storage_class
  postgres_user         = var.postgres_user
  postgres_password     = var.postgres_password
  postgres_database     = var.postgres_database

  # Redis Configuration
  redis_image        = var.redis_image
  redis_storage_size = var.redis_storage_size
  redis_storage_class = var.redis_storage_class

  # Secrets
  jwt_secret_key = var.jwt_secret_key
  ghcr_username  = var.ghcr_username
  ghcr_token     = var.ghcr_token

  # Resource Limits
  backend_cpu_request    = var.backend_cpu_request
  backend_cpu_limit      = var.backend_cpu_limit
  backend_memory_request = var.backend_memory_request
  backend_memory_limit   = var.backend_memory_limit

  # Ingress
  enable_ingress = var.enable_ingress
  ingress_host   = var.ingress_host
  ingress_class  = var.ingress_class
  enable_tls     = var.enable_tls

  # Frontend Configuration
  frontend_image           = var.frontend_image
  frontend_replicas        = var.frontend_replicas
  enable_frontend_ingress  = var.enable_frontend_ingress
  frontend_ingress_host    = var.frontend_ingress_host
  frontend_tls_secret_name = var.frontend_tls_secret_name

  # Labels
  common_labels = merge(
    var.common_labels,
    {
      "environment" = "pi-cluster"
      "architecture" = "arm64"
    }
  )
}
