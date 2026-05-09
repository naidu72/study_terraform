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

# Kubernetes Provider - Using k8s-k8s context
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

# Use the main module
module "inventory_manager" {
  source = "../.."

  # Kubernetes Config
  kubeconfig_path    = var.kubeconfig_path
  kubeconfig_context = var.kubeconfig_context

  # Application Config
  namespace      = var.namespace
  app_name       = var.app_name
  backend_image  = var.backend_image
  backend_tag    = var.backend_tag
  replicas       = var.replicas

  # PostgreSQL Config
  postgres_image        = var.postgres_image
  postgres_storage_size = var.postgres_storage_size
  postgres_user         = var.postgres_user
  postgres_password     = var.postgres_password
  postgres_db           = var.postgres_db

  # Redis Config
  redis_image        = var.redis_image
  redis_storage_size = var.redis_storage_size

  # Security
  jwt_secret_key = var.jwt_secret_key
  ghcr_username  = var.ghcr_username
  ghcr_token     = var.ghcr_token

  # Resource Limits
  backend_cpu_request    = var.backend_cpu_request
  backend_memory_request = var.backend_memory_request
  backend_cpu_limit      = var.backend_cpu_limit
  backend_memory_limit   = var.backend_memory_limit

  postgres_cpu_request    = var.postgres_cpu_request
  postgres_memory_request = var.postgres_memory_request
  postgres_cpu_limit      = var.postgres_cpu_limit
  postgres_memory_limit   = var.postgres_memory_limit

  redis_cpu_request    = var.redis_cpu_request
  redis_memory_request = var.redis_memory_request
  redis_cpu_limit      = var.redis_cpu_limit
  redis_memory_limit   = var.redis_memory_limit

  # Ingress Config
  enable_ingress = var.enable_ingress
  ingress_host   = var.ingress_host
  tls_enabled    = var.tls_enabled

  # Labels
  environment = var.environment
  common_labels = merge(
    var.common_labels,
    {
      "cluster" = "k8s-k8s"
      "arch"    = "amd64"
    }
  )
}
