# Alternative Build Strategies for Frontend

## Problem
Multi-arch Docker builds for React applications can take hours or hang due to:
1. TypeScript compilation on ARM64 emulation (QEMU)
2. High memory usage during webpack/babel compilation
3. Fork-ts-checker-webpack-plugin memory issues

## Solution Options

### Option 1: Build on Native Architecture (RECOMMENDED)
Build images separately on their respective architectures.

#### On AMD64 machine (your current machine):
```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/app/frontend

# Build for AMD64
docker build --platform linux/amd64 \
  -t ghcr.io/naidu72/inventory-frontend:amd64 \
  -t naidu72/inventory-frontend:amd64 \
  .

# Push to registries
docker push ghcr.io/naidu72/inventory-frontend:amd64
docker push naidu72/inventory-frontend:amd64
```

#### On ARM64 machine (Raspberry Pi):
```bash
# SSH to your Raspberry Pi
ssh pi@<raspberry-pi-ip>

# Clone repo or copy files
cd /path/to/project/app/frontend

# Build for ARM64
docker build --platform linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:arm64 \
  -t naidu72/inventory-frontend:arm64 \
  .

# Push to registries
docker push ghcr.io/naidu72/inventory-frontend:arm64
docker push naidu72/inventory-frontend:arm64
```

#### Create multi-arch manifest:
```bash
# Create and push manifest list
docker manifest create ghcr.io/naidu72/inventory-frontend:latest \
  ghcr.io/naidu72/inventory-frontend:amd64 \
  ghcr.io/naidu72/inventory-frontend:arm64

docker manifest push ghcr.io/naidu72/inventory-frontend:latest

# Same for Docker Hub
docker manifest create naidu72/inventory-frontend:latest \
  naidu72/inventory-frontend:amd64 \
  naidu72/inventory-frontend:arm64

docker manifest push naidu72/inventory-frontend:latest
```

### Option 2: Use Pre-built Static Files (FASTEST)
Build once locally, then copy into Docker image.

```bash
cd /home/frontier/terraform/study_terraform/inventory-manager/app/frontend

# Build locally (already done - we have the build folder)
npm run build

# Create simplified Dockerfile
cat > Dockerfile.simple <<'EOF'
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build multi-arch from pre-built files (FAST - no npm install/build)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  -t naidu72/inventory-frontend:latest \
  -f Dockerfile.simple \
  --push .
```

### Option 3: Build Only for Target Architecture
If you're primarily deploying to Raspberry Pi:

```bash
# Build only ARM64
docker buildx build --platform linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  -t naidu72/inventory-frontend:latest \
  --push .
```

If you need AMD64 for testing:
```bash
# Build only AMD64
docker build --platform linux/amd64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  .
```

### Option 4: Use GitHub Actions (Future - Phase 5)
Let GitHub's runners build on native hardware:
- AMD64 runner builds AMD64 image
- ARM64 runner builds ARM64 image
- Manifest combines them

## RECOMMENDED APPROACH FOR NOW

Since you already have a working `build/` folder from `npm run build`, use **Option 2**:

```bash
#!/bin/bash
cd /home/frontier/terraform/study_terraform/inventory-manager/app/frontend

# Create simple Dockerfile that just copies pre-built files
cat > Dockerfile.simple <<'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build multi-arch (FAST - only copying static files, no npm!)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/naidu72/inventory-frontend:latest \
  -t naidu72/inventory-frontend:latest \
  -f Dockerfile.simple \
  --push .
```

This will complete in **under 2 minutes** instead of 3+ hours!

## Why This Works

The React build creates static HTML/CSS/JS files that are architecture-independent. Only the Nginx binary needs to be multi-arch, and Nginx provides official multi-arch images. This approach:

✅ Builds in seconds instead of hours
✅ No memory issues
✅ No TypeScript compilation in Docker
✅ Same result - optimized production build
✅ Works on both amd64 and arm64

## Next Steps

1. Stop current hanging build (already done)
2. Use Option 2 with pre-built static files
3. Complete Phase 2 in minutes!
