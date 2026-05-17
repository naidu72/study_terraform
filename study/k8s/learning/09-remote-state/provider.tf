terraform {
  required_providers {
    kubernetes ={
        source = "hashicorp/kubernetes"
        version = "~>3.1"
    }
  }
}
provider "kubernetes" {
    config_path = "~/.kube/pi-cluster"
    config_context = "pi-k8s"
}