# Phase 2 Quick Reference

## 🚀 Quick Commands

### 1. Authenticate to GHCR (One-time setup)
```bash
# Get token from: https://github.com/settings/tokens/new
export GITHUB_TOKEN=ghp_your_token_here
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin
```

### 2. Build Multi-arch Images
```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/build-multiarch.sh
```

### 3. Test Images
```bash
./scripts/test-images.sh latest ghcr.io naidu72
```

### 4. Verify on Pi
```bash
docker pull ghcr.io/naidu72/inventory-backend:latest
docker inspect ghcr.io/naidu72/inventory-backend:latest | grep Architecture
```

## 📋 Build Options

```bash
# Default (latest tag)
./scripts/build-multiarch.sh

# Specific version
./scripts/build-multiarch.sh v1.0.0

# With custom username
GITHUB_USERNAME=yourname ./scripts/build-multiarch.sh
```

## 🔍 Inspection Commands

```bash
# View multi-arch manifest
docker buildx imagetools inspect ghcr.io/naidu72/inventory-backend:latest

# Check builder status
docker buildx ls

# View builder details
docker buildx inspect inventory-builder
```

## 🧹 Cleanup Commands

```bash
# Remove builder
docker buildx rm inventory-builder

# Recreate builder
docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use
docker buildx inspect --bootstrap

# Remove local images
docker rmi ghcr.io/naidu72/inventory-backend:latest
```

## 📊 Image URLs

After build, your images will be at:
- `ghcr.io/naidu72/inventory-backend:latest`
- `ghcr.io/naidu72/inventory-backend:v1.0.0`
- `naidu72/inventory-backend:latest` (if Docker Hub authenticated)
- `naidu72/inventory-backend:v1.0.0` (if Docker Hub authenticated)

## 🎯 Status at a Glance

Run this to see your setup:
```bash
echo "=== Builder ===" && docker buildx ls | grep inventory-builder
echo "=== Authenticated Registries ===" && cat ~/.docker/config.json | jq -r '.auths | keys[]'
echo "=== Backend Dockerfile ===" && ls -lh app/backend/Dockerfile
```

## ⚡ Full Workflow

```bash
# 1. Authenticate (one time)
export GITHUB_TOKEN=ghp_xxx
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin

# 2. Build
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/build-multiarch.sh

# 3. Test
./scripts/test-images.sh latest ghcr.io naidu72

# 4. Deploy (Phase 3)
# Will use: ghcr.io/naidu72/inventory-backend:latest in K8s manifests
```

## 🆘 Troubleshooting

### Builder Issues
```bash
docker buildx rm inventory-builder
docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use
```

### Auth Issues
```bash
# Re-authenticate
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin

# Check auth
cat ~/.docker/config.json | jq '.auths."ghcr.io"'
```

### Build Fails
```bash
# Check logs
docker buildx build --progress=plain ...

# Clean build (no cache)
docker buildx build --no-cache ...
```

## 📚 More Info

- Full guide: `docs/PHASE2_README.md`
- Status: `docs/PHASE2_STATUS.md`
- Auth help: `docs/AUTHENTICATION_GUIDE.md`
