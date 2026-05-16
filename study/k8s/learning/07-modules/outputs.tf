output "app_namespace" {
  value = module.app_namespace.name
}

output "monitoring_namespace" {
  value = module.monitoring_namespace.name
}
output "app_namespace_env" {
  value = module.app_namespace.labels["environment"]
}

output "app_monitoring_env" {
  value = module.monitoring_namespace.labels["environment"]
}