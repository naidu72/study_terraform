# ── Data source: look up latest nginx image ──────────────────
# Terraform reads this at plan time — we don't manage the image,
# we just reference it. This is the data vs resource distinction.
data "docker_image" "nginx" {
  name = "nginx:${var.nginx_version}"
}

data "docker_image" "postgres" {
  name = "postgres:${var.postgres_version}"
}

# ── Docker network ────────────────────────────────────────────
resource "docker_network" "app" {
  name = local.network_name

  lifecycle {
    # If we rename the network, create the new one first
    # so containers aren't briefly disconnected
    create_before_destroy = false
  }
}

# ── Nginx container ───────────────────────────────────────────
resource "docker_container" "nginx" {
  name  = local.nginx_name
#   image = data.docker_image.nginx.image_id  #v2
  image =  data.docker_image.nginx.repo_digest #v3

  ports {
    internal = 80
    external = var.nginx_port
  }

  networks_advanced {
    name = docker_network.app.name
  }

  env = [
    "NGINX_HOST=${local.app_fqdn}",
    "NGINX_PORT=80",
  ]

  lifecycle {
    # Autoscalers or health checks may update the container label
    # externally — we don't want Terraform to fight that
    ignore_changes = [labels]

    # Protect the nginx container from accidental destroy
    # in production workspaces
    # prevent_destroy = var.env == "prod" ? true : false
    prevent_destroy     = false
  }
}

# ── Postgres container ────────────────────────────────────────
resource "docker_container" "postgres" {
  name  = local.postgres_name
#   image = data.docker_image.postgres.image_id #v2
    image = data.docker_image.postgres.repo_digest #v3

  ports {
    internal = 5432
    external = var.postgres_port
  }

  networks_advanced {
    name = docker_network.app.name
  }

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  lifecycle {
    create_before_destroy = true
    # Password changes shouldn't force container recreation
    ignore_changes = [env]
  }
}