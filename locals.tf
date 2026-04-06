locals {
  # Naming convention: {env}-{project}-{component}
  # Computed once here, referenced everywhere else
  name_prefix   = "${var.env}-${var.project}" # dev-homelab
  network_name  = "${local.name_prefix}-net"  # dev-homelab-net
  nginx_name    = "${local.name_prefix}-nginx" #dev-homelab-nginx
  postgres_name = "${local.name_prefix}-postgres"

  # Fake FQDN used in nginx env config
  app_fqdn = "${var.project}.${var.env}.local"  #homelab.

  # Common labels applied to all containers
  common_labels = {
    environment = var.env
    project     = var.project
    managed_by  = "terraform"
  }

  # Derived: is this a production-grade env?
  #is_prod = var.env == "prod"
  is_prod = terraform.workspace == "prod"
}