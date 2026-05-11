# Kubernetes Provider Configuration
# Can be configured for different clusters using environment variables or kubeconfig

provider "kubernetes" {
  # Will use KUBECONFIG environment variable or ~/.kube/config by default
  # Can override with config_path variable
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}
