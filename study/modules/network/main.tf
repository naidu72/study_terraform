terraform {
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

resource "docker_network" "this" {
  name   = var.name
  driver = var.driver

  dynamic "labels" {
    for_each = var.labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
