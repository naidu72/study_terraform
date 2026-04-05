terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ── Phase 1: locals inside the module ─────────────────────────
# These are internal — callers never see or set them directly
locals {
  # Consistent label set stamped on every container this module creates
  labels = {
    environment = var.env
    managed_by  = "terraform"
    service     = var.name
  }
}

# ── Phase 1: data source — read the image, don't manage it ────
data "docker_image" "this" {
  name = var.image
  # "this" is the convention for single-resource modules
}

# ── Phase 2: the single resource the module wraps ─────────────
resource "docker_container" "this" {
  name   = var.name
  image  = data.docker_image.this.image_id

  ports {
    internal = var.internal_port
    external = var.external_port
  }

  networks_advanced {
    name = var.network_name
  }

  # Convert env_vars map → ["KEY=value", ...] list Docker expects
  env = [for k, v in var.env_vars : "${k}=${v}"]

  labels {
    for_each = local.labels   # stamp every label from locals
    label    = each.key
    value    = each.value
  }

  # ── Phase 1: lifecycle rules ───────────────────────────────
  lifecycle {
    # New container created before old one is destroyed —
    # avoids a gap where the port is unavailable
    create_before_destroy = true

    # External tooling (health checkers, orchestrators) may
    # update labels — we don't want Terraform to fight that
    ignore_changes = [labels]

    # Only active when caller passes protected = true
    # Prevents accidental destroy in prod
    prevent_destroy = var.protected
  }
}