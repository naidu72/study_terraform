#!/bin/bash
set -e

echo "🚀 Quick Frontend Multi-Arch Build"
echo "===================================="
echo ""

cd /home/frontier/terraform/study_terraform/inventory-manager/app/frontend

# Check if build folder exists
if [ ! -d "build" ]; then
    echo "❌ Build folder not found! Run 'npm run build' first."
    exit 1
fi

echo "✅ Found pre-built static files in build/"
echo ""

# Create simplified Dockerfile
echo "📝 Creating optimized Dockerfile.simple..."
cat > Dockerfile.simple <<'EOF'
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy pre-built static files
COPY build /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

echo "✅ Dockerfile.simple created"
echo ""

# Check Docker login status
echo "🔐 Checking Docker registry authentication..."

if ! docker info 2>/dev/null | grep -q "Username"; then
    echo "⚠️  Not logged in to Docker Hub. Logging in..."
    docker login
fi

# Check GHCR login
if ! grep -q "ghcr.io" ~/.docker/config.json 2>/dev/null; then
    echo "⚠️  Not logged in to GHCR. Please login:"
    echo "   docker login ghcr.io -u naidu72"
    read -p "Press enter after logging in to GHCR..."
fi

echo ""
echo "🏗️  Building multi-arch image (amd64 + arm64)..."
echo "This should take ~1-2 minutes (just copying files, no npm build!)"
echo ""

# Build and push multi-arch image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag ghcr.io/naidu72/inventory-frontend:latest \
    --tag naidu72/inventory-frontend:latest \
    --file Dockerfile.simple \
    --push \
    .

echo ""
echo "✅ Multi-arch build complete!"
echo ""
echo "📦 Images pushed to:"
echo "   • ghcr.io/naidu72/inventory-frontend:latest"
echo "   • naidu72/inventory-frontend:latest"
echo ""
echo "🎉 Phase 2 (Containerization) - FRONTEND DONE!"
