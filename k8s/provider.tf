terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}

# Option A — use current kubeconfig context (simplest for local work)
provider "kubernetes" {
  config_path    = "~/.kube/local"
  config_context = "kind-k8s-kind"   # your KIND context name
}

# Option B — explicit fields (better for CI or when managing
# multiple clusters — you'd pull these from a data source or var)
# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_ca)
#   token                  = var.cluster_token
# }
