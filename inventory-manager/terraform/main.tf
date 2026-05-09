# Inventory Manager - Main Terraform Configuration
# Deploys the full application stack to Kubernetes

# Namespace Module
module "namespace" {
  source = "./modules/namespace"

  name        = var.namespace
  environment = var.environment
  labels      = var.common_labels
}

# Common Secrets Module (GHCR secret shared by all components)
module "common_secrets" {
  source = "./modules/common-secrets"

  namespace     = module.namespace.name
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
  labels        = var.common_labels

  depends_on = [module.namespace]
}

# PostgreSQL Module
module "postgresql" {
  source = "./modules/postgresql"

  namespace        = module.namespace.name
  app_name         = var.app_name
  image            = var.postgres_image
  storage_size     = var.postgres_storage_size
  storage_class    = var.postgres_storage_class
  postgres_user    = var.postgres_user
  postgres_password = var.postgres_password
  postgres_database = var.postgres_database
  labels           = var.common_labels

  depends_on = [module.namespace]
}

# Redis Module
module "redis" {
  source = "./modules/redis"

  namespace     = module.namespace.name
  app_name      = var.app_name
  image         = var.redis_image
  storage_size  = var.redis_storage_size
  storage_class = var.redis_storage_class
  labels        = var.common_labels

  depends_on = [module.namespace]
}

# Backend Application Module
module "backend" {
  source = "./modules/backend"

  namespace           = module.namespace.name
  app_name            = var.app_name
  image               = var.backend_image
  replicas            = var.backend_replicas
  cpu_request         = var.backend_cpu_request
  cpu_limit           = var.backend_cpu_limit
  memory_request      = var.backend_memory_request
  memory_limit        = var.backend_memory_limit
  postgres_host       = module.postgresql.service_name
  postgres_port       = module.postgresql.service_port
  postgres_user       = var.postgres_user
  postgres_password   = var.postgres_password
  postgres_database   = var.postgres_database
  redis_host          = module.redis.service_name
  redis_port          = module.redis.service_port
  jwt_secret_key      = var.jwt_secret_key
  ghcr_username       = var.ghcr_username
  ghcr_token          = var.ghcr_token
  ghcr_secret_name    = module.common_secrets.ghcr_secret_name
  labels              = var.common_labels
  enable_ingress      = var.enable_ingress
  ingress_host        = var.ingress_host
  ingress_class       = var.ingress_class
  enable_tls          = var.enable_tls

  depends_on = [
    module.namespace,
    module.common_secrets,
    module.postgresql,
    module.redis
  ]
}

# Frontend Application Module
module "frontend" {
  source = "./modules/frontend"

  namespace            = module.namespace.name
  image                = var.frontend_image
  replicas             = var.frontend_replicas
  backend_service_url  = "http://${module.backend.service_name}:${module.backend.service_port}"
  backend_service_name = module.backend.service_name
  ghcr_username        = var.ghcr_username
  ghcr_token           = var.ghcr_token
  ghcr_secret_name     = module.common_secrets.ghcr_secret_name
  labels               = var.common_labels
  enable_ingress       = var.enable_frontend_ingress
  ingress_host         = var.frontend_ingress_host
  ingress_class        = var.ingress_class
  enable_tls           = var.enable_tls
  tls_secret_name      = var.frontend_tls_secret_name

  depends_on = [
    module.namespace,
    module.common_secrets,
    module.backend
  ]
}
