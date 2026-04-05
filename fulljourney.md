terraform.tfvars          root variables.tf        root main.tf
────────────────          ─────────────────        ────────────
nginx_version = "stable"  variable "nginx_version" image = "nginx:${var.nginx_version}"
      │                         │                        │
      └──────────────────────── ┘                        │
                                                         │ resolves to
                                                         ▼
                                                   "nginx:stable"
                                                         │
                                                         │ passed into module
                                                         ▼
                                          modules/docker-service/variables.tf
                                          variable "image" { type = string }
                                                         │
                                                         │ now available as
                                                         ▼
                                          modules/docker-service/main.tf
                                          data "docker_image" "this" {
                                            name = var.image  → "nginx:stable"
                                          }
