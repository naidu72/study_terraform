resource "kubernetes_namespace_v1" "tf_namespace" {
    metadata {
      name = var.namespace_name
      labels ={
      team   =  var.namespace_config.name
      environment = var.namespace_config.environment
      resource_count = var.namespace_config.replicas
      }
    }
  
}
