module "app_namespace" {
  source      = "./modules/namespace"
  name        = "lesson7-app"
  team        = "backend"
  environment = "qa"
}

module "monitoring_namespace" {
  source      = "./modules/namespace"
  name        = "lesson7-monitoring"
  team        = "platform01"
  environment = "dev"
}
