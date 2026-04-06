# Shared network — still a root-level resource
# (not in the module because multiple services share it)
# resource "docker_network" "app" {
#   name = local.network_name
#   lifecycle { create_before_destroy = true }
# }
# ── Module 1: network ─────────────────────────────────────────
# Creates the shared Docker network all services attach to.
module "network" {
  source = "./modules/network"

  name   = local.network_name
  driver = "bridge"
  labels = local.common_labels
}
# ── Module 2: services — for_each on the module call ──────────
#
# var.services is a map defined in variables.tf and set in
# terraform.tfvars. ONE module block creates ALL services.
# Adding a new service = one entry in tfvars, zero code changes.
#
module "service" {
  for_each = var.services          # key = service name

  source = "./modules/docker-service"

  name          = "${local.name_prefix}-${each.key}"
  image         = each.value.image
  internal_port = each.value.internal_port
  external_port = each.value.external_port
  network_name  = module.network.network_name
  env           = var.env
  protected     = var.env == "prod"
  env_vars      = lookup(each.value, "env_vars", {})

  # ── depends_on: the critical Phase 2 concept ─────────────
  # The network module creates the Docker network.
  # docker-service attaches containers to it.
  # There is no direct attribute reference between them
  # (network_name is a string, not a resource reference) —
  # so Terraform can't infer the dependency automatically.
  # We must declare it explicitly.
  depends_on = [module.network]
}