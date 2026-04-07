terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.27" }
    helm       = { source = "hashicorp/helm",       version = "~> 2.13" }
  }
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/pi-cluster.yaml"
    config_context = "kind-pi-cluster"
  }
}

# Important: both kubernetes and helm providers must point
# at the same cluster — keep their config in sync
