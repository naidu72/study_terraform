output "kube_system_labels" {
    value = data.kubernetes_namespace_v1.kube-system.metadata[0].labels
  
}
output "kube_system_uid" {
    value = data.kubernetes_namespace_v1.kube-system.metadata[0].resource_version
  
}
output "endpoint" {
  value = one([
    for subset in data.kubernetes_endpoints_v1.ep.subset : 
      tolist(subset.addresses)[0].ip
  ])
}