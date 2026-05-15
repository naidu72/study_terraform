locals {
  name_prefix = "${var.environment}-${var.team}"
  namespce_name = "${local.name_prefix}-${var.app}"
  common_labels = {
    team = var.team
    environment = "stage"
    manged_by = "terraform"
  }
}