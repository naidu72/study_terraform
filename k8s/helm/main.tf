resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"          # always pin in Terraform
  namespace  = "ingress-nginx1"
  create_namespace = true        # saves a separate namespace resource

  set {
    name  = "controller.service.type"
    value = "NodePort"           # NodePort works on KIND/Pi without LB
  }

  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }

  # Pass structured values with values = [yamlencode(...)]
  values = [yamlencode({
    controller = {
      replicaCount = 1
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
      }
    }
  })]

  timeout = 300   # seconds — charts with many resources need time
  wait    = true  # block until all pods are Running
}
