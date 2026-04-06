# Shared network — still a root-level resource
# (not in the module because multiple services share it)
resource "docker_network" "app" {
  name = local.network_name
  lifecycle { create_before_destroy = true }
}

# ── Call the module for nginx ──────────────────────────────────
module "nginx" {
  source = "./modules/docker-service"

  name          = local.nginx_name       # from root locals.tf  dev-homelab-nginx(this from local.tf)
  image         = "nginx:${var.nginx_version}" # nginx:stable veriable.tf L22 to L25
  internal_port = 80
  external_port = var.nginx_port
  network_name  = docker_network.app.name #dev-homelab-net
  env           = var.env
  protected     = var.env == "prod"      # true only in prod

  env_vars = {
    NGINX_HOST = local.app_fqdn
    NGINX_PORT = "80"
  }
}

# ── Call the same module for postgres ─────────────────────────
module "postgres" {
  source = "./modules/docker-service"

  name          = local.postgres_name
  image         = "postgres:${var.postgres_version}"
  internal_port = 5432
  external_port = var.postgres_port
  network_name  = docker_network.app.name
  env           = var.env
  protected     = var.env == "prod"

  env_vars = {
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
}

# ── Root outputs — pull from module outputs ────────────────────
#output "nginx_url"   { value = module.nginx.url }
output "postgres_url"{ value = module.postgres.url }

output "all_containers" {
  sensitive = true
  value = {
    nginx    = module.nginx.container_id
    postgres = module.postgres.container_id
  }
}
