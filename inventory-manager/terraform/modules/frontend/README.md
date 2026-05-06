# Frontend Module

Terraform module for deploying the Inventory Manager React frontend to Kubernetes.

## Features

- 🚀 Multi-arch support (amd64 + arm64)
- 🔐 Secure GHCR image pull
- 🌐 Ingress with TLS support
- 📊 Horizontal Pod Autoscaler
- ♻️ Rolling updates (zero downtime)
- 🏥 Health checks (liveness + readiness)
- 🔗 API proxy to backend

## Usage

```hcl
module "frontend" {
  source = "./modules/frontend"

  namespace            = "inventory-manager"
  image                = "ghcr.io/naidu72/inventory-frontend:latest"
  replicas             = 2
  backend_service_url  = "http://backend-service:8000"
  ghcr_username        = "your-username"
  ghcr_token           = var.ghcr_token
  enable_ingress       = true
  ingress_host         = "inventory.example.com"
  ingress_class        = "nginx"
  enable_tls           = true
}
```

## Resources Created

- `kubernetes_secret.ghcr` - GHCR image pull secret
- `kubernetes_config_map.frontend` - Frontend configuration
- `kubernetes_deployment.frontend` - Frontend deployment (2 replicas default)
- `kubernetes_service.frontend` - ClusterIP service (port 80)
- `kubernetes_ingress_v1.frontend` - Ingress for external access
- `kubernetes_horizontal_pod_autoscaler_v2.frontend` - HPA (2-6 replicas)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| namespace | Kubernetes namespace | string | n/a | yes |
| app_name | Application name | string | "inventory-manager-frontend" | no |
| image | Docker image for frontend | string | "ghcr.io/naidu72/inventory-frontend:latest" | no |
| replicas | Number of replicas | number | 2 | no |
| backend_service_url | Backend API URL (internal) | string | n/a | yes |
| enable_ingress | Enable ingress | bool | true | no |
| ingress_host | Ingress hostname | string | "inventory.naidu72.info" | no |
| ingress_class | Ingress class name | string | "nginx" | no |
| enable_tls | Enable TLS | bool | true | no |
| tls_secret_name | TLS secret name | string | "inventory-frontend-tls" | no |
| ghcr_username | GHCR username | string | "" | no |
| ghcr_token | GHCR token | string | "" | yes |
| labels | Labels to apply | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| deployment_name | Frontend deployment name |
| service_name | Frontend service name |
| service_url | Internal service URL |
| ingress_host | Ingress hostname |
| ingress_url | Public URL |
| replicas | Number of replicas |

## Resource Requirements

- **CPU**: 50m request, 200m limit
- **Memory**: 64Mi request, 128Mi limit
- **Replicas**: 2-6 (auto-scaling)

## Health Checks

### Liveness Probe
- Path: `/`
- Port: 80
- Initial delay: 10s
- Period: 10s

### Readiness Probe
- Path: `/`
- Port: 80
- Initial delay: 5s
- Period: 5s

## Ingress Configuration

The ingress routes:
- `/*` → Frontend Service:80 (React app)
- `/api/*` → Backend Service:8000 (API proxy)

This allows the entire application to be served from a single domain.

## Multi-Arch Support

The module works with multi-arch images built with:
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  --push .
```

## Example: Pi Cluster Deployment

```hcl
module "frontend" {
  source = "../../modules/frontend"

  namespace            = "inventory-manager"
  image                = "ghcr.io/naidu72/inventory-frontend:latest"
  replicas             = 2
  backend_service_url  = "http://inventory-manager-backend-service:8000"
  ghcr_username        = "naidu72"
  ghcr_token           = var.ghcr_token
  enable_ingress       = true
  ingress_host         = "inventory-pi.naidu72.info"
  ingress_class        = "nginx"
  enable_tls           = true
  tls_secret_name      = "inventory-frontend-pi-tls"
  
  labels = {
    "environment"  = "pi-cluster"
    "architecture" = "arm64"
  }
}
```

## Dependencies

- Kubernetes cluster with nginx-ingress-controller
- cert-manager (for TLS certificates)
- Backend service already deployed
- GHCR token with read access to the image
