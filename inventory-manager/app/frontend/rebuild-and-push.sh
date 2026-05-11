#!/bin/bash
set -e

cd /home/frontier/terraform/study_terraform/inventory-manager/app/frontend

echo "🔨 Building frontend image..."
docker buildx build --platform linux/arm64,linux/amd64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  --push \
  .

echo "✅ Frontend image built and pushed successfully!"
echo ""
echo "Next steps:"
echo "1. Update the deployment with: kubectl rollout restart deployment/inventory-manager-frontend -n inventory-manager"
echo "2. Or rerun: terraform apply"
