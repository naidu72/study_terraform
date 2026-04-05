terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ── locals inside the module ───────────────────────────────────
locals {
  labels = {
    environment = var.env
    managed_by  = "terraform"
    service     = var.name
  }
}

# ── data source — read the image, don't manage it ─────────────
data "docker_image" "this" {
  name = var.image
}

# ── protected = true (prod) ────────────────────────────────────
# prevent_destroy must be a static literal — Terraform language constraint.
# var.protected controls which of the two resources below gets count = 1.
resource "docker_container" "protected" {
  count = var.protected ? 1 : 0

  name  = var.name
  image = data.docker_image.this.repo_digest

  ports {
    internal = var.internal_port
    external = var.external_port
  }
  networks_advanced {
    name = var.network_name
  }
  env = [for k, v in var.env_vars : "${k}=${v}"]
  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [labels]
    prevent_destroy       = true      # static literal — protected path
  }
}

# ── protected = false (non-prod) ───────────────────────────────
resource "docker_container" "unprotected" {
  count = var.protected ? 0 : 1

  name  = var.name
  image = data.docker_image.this.repo_digest

  ports {
    internal = var.internal_port
    external = var.external_port
  }
  networks_advanced {
    name = var.network_name
  }
  env = [for k, v in var.env_vars : "${k}=${v}"]
  dynamic "labels" {
    for_each = local.labels
    content {
      label = labels.key
      value = labels.value
    }
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [labels]
    prevent_destroy       = false     # static literal — unprotected path
  }
}

# ── single reference for outputs ──────────────────────────────
# Collapses the two resources back into one so outputs.tf and
# any other module internals don't need to branch on var.protected
locals {
  container = var.protected ? one(docker_container.protected) : one(docker_container.unprotected)
}

