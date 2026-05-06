# Ingress Configuration Update - Cloudflare Tunnel

## Changes Made

✅ **Updated for Cloudflare Tunnel integration**

### 1. Ingress Class Changed
- **Before**: `nginx`
- **After**: `cloudflare-tunnel`

### 2. Removed Cert-Manager Integration
- Removed `cert-manager.io/cluster-issuer` annotation
- Removed TLS configuration block
- Cloudflare Tunnel handles SSL/TLS automatically

### 3. Removed Nginx Annotations
- Removed `nginx.ingress.kubernetes.io/ssl-redirect`
- Removed `nginx.ingress.kubernetes.io/force-ssl-redirect`
- Removed `nginx.ingress.kubernetes.io/rewrite-target`
- Removed `nginx.ingress.kubernetes.io/use-regex`

### 4. Simplified Path Patterns
- **Before**: `/(.*)`  and `/api/(.*)`
- **After**: `/*` and `/api/*`

## Final Ingress Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: inventory-manager-frontend-ingress
  namespace: inventory-manager
spec:
  ingressClassName: cloudflare-tunnel
  rules:
  - host: inventory-pi.naidu72.info
    http:
      paths:
      - path: /*
        pathType: Prefix
        backend:
          service:
            name: inventory-manager-frontend-service
            port:
              number: 80
      - path: /api/*
        pathType: Prefix
        backend:
          service:
            name: inventory-manager-backend-service
            port:
              number: 8000
```

## Comparison with MinIO Example

### Your MinIO Example:
```bash
kubectl -n minio \
  create ingress minio-ui \
  --rule="s3.naidu72.info/*=minio-webconsole-service:9001" \
  --class cloudflare-tunnel
```

### Our Inventory Manager Ingress:
- ✅ Same ingress class: `cloudflare-tunnel`
- ✅ Same pattern: host with path rules
- ✅ No TLS config (Cloudflare handles it)
- ✅ Multiple paths:
  - `/*` → frontend-service:80
  - `/api/*` → backend-service:8000

## Files Updated

1. **terraform/modules/frontend/main.tf**
   - Removed cert-manager annotations
   - Removed nginx-specific annotations
   - Removed TLS configuration
   - Simplified path patterns

2. **terraform/modules/frontend/variables.tf**
   - Changed default ingress_class from `nginx` to `cloudflare-tunnel`

3. **terraform/environments/pi-cluster/terraform.tfvars**
   - Added explicit `ingress_class = "cloudflare-tunnel"`

## Deployment Status

✅ **Plan regenerated**: 21 resources to be created
✅ **Ingress verified**: Using cloudflare-tunnel class
✅ **Ready to deploy**: terraform apply tfplan

## Access After Deployment

- **URL**: https://inventory-pi.naidu72.info
- **SSL/TLS**: Handled by Cloudflare Tunnel automatically
- **DNS**: Managed by Cloudflare
- **No cert-manager needed**: Cloudflare provides certificates

## Benefits of Cloudflare Tunnel

1. ✅ **Automatic SSL/TLS** - No certificate management needed
2. ✅ **DDoS Protection** - Cloudflare's global network
3. ✅ **Simplified DNS** - No need to expose cluster IP
4. ✅ **Zero Trust Access** - Optional authentication layers
5. ✅ **Performance** - Cloudflare CDN and caching

## Verification Commands

After deployment:

```bash
# Check ingress
kubectl get ingress -n inventory-manager \
  --kubeconfig=/home/frontier/.kube/pi-cluster \
  --context=pi-k8s

# Expected output:
# NAME                               CLASS              HOSTS                        ADDRESS   PORTS   AGE
# inventory-manager-frontend-ingress cloudflare-tunnel  inventory-pi.naidu72.info              80      1m

# Describe ingress
kubectl describe ingress inventory-manager-frontend-ingress \
  -n inventory-manager \
  --kubeconfig=/home/frontier/.kube/pi-cluster \
  --context=pi-k8s

# Test frontend
curl https://inventory-pi.naidu72.info

# Test API
curl https://inventory-pi.naidu72.info/api/v1/health
```

---

**Updated**: $(date)
**Status**: Ready for deployment
**Next**: Run `terraform apply tfplan`
