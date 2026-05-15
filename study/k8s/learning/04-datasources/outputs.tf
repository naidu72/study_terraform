output "kube_system_labels" {
    value = data.kubernetes_namespace_v1.kube-sysyem.metadata[0].labels
  
}
output "kube_system_uid" {
    value = data.kubernetes_namespace_v1.kube-sysyem.metadata[0].resource_version
  
}