# Phase 2 - Multi-arch Docker Builds & Registry Push

## ✅ Status: Ready to Execute

This phase builds multi-architecture Docker images (amd64 + arm64) and pushes them to both GitHub Container Registry and Docker Hub.

## 🎯 What We'll Accomplish

- ✅ Set up Docker Buildx for multi-platform builds
- ✅ Build images for `linux/amd64` and `linux/arm64`
- ✅ Push to GitHub Container Registry (ghcr.io)
- ✅ Push to Docker Hub
- ✅ Verify images work on both architectures
- ✅ Optimize image sizes

## 📋 Prerequisites

### 1. Docker Buildx
Already verified and configured:
- Builder: `inventory-builder`
- Platforms: `linux/amd64`, `linux/arm64`

### 2. Registry Authentication

#### Option 1: GitHub Container Registry
```bash
# Create token at: https://github.com/settings/tokens/new
# Required scopes: read:packages, write:packages

export GITHUB_TOKEN=<your-token>
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin
```

#### Option 2: Docker Hub
```bash
docker login
# Enter username: naidu72
# Enter password: <your-docker-hub-password>
```

## 🚀 Quick Start

### Step 1: Authenticate to Registries
```bash
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/setup-registry-auth.sh
```

### Step 2: Build and Push Images
```bash
# Build and push with 'latest' tag
./scripts/build-multiarch.sh

# Or specify a version
./scripts/build-multiarch.sh v1.0.0
```

### Step 3: Test Images
```bash
# Test GHCR images
./scripts/test-images.sh latest ghcr.io naidu72

# Test Docker Hub images
./scripts/test-images.sh latest docker.io naidu72
```

## 📦 What Gets Built

### Backend Image
- **Name**: `inventory-backend`
- **Base**: `python:3.11-slim`
- **Size**: ~150-200MB (multi-stage optimized)
- **Platforms**: linux/amd64, linux/arm64

**Pushed to:**
- `ghcr.io/naidu72/inventory-backend:latest`
- `ghcr.io/naidu72/inventory-backend:v1.0.0`
- `naidu72/inventory-backend:latest`
- `naidu72/inventory-backend:v1.0.0`

### Frontend Image (Future)
- **Name**: `inventory-frontend`
- **Base**: `node:18-alpine` + `nginx:alpine`
- **Platforms**: linux/amd64, linux/arm64

## 🔧 Build Process

The multi-arch build process:

1. **Setup**: Uses `inventory-builder` with Docker Buildx
2. **Build**: Compiles for both amd64 and arm64 simultaneously
3. **Push**: Uploads to both registries in parallel
4. **Verify**: Inspects and tests images

### Build Architecture

```
┌─────────────────────────────────────────┐
│     Docker Buildx (inventory-builder)   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐    ┌─────────────┐   │
│  │ linux/amd64 │    │ linux/arm64 │   │
│  │   builder   │    │   builder   │   │
│  └──────┬──────┘    └──────┬──────┘   │
│         │                  │           │
└─────────┼──────────────────┼───────────┘
          │                  │
          └────────┬─────────┘
                   │
         ┌─────────▼──────────┐
         │   Multi-arch       │
         │   Manifest         │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │                    │
    ┌────▼─────┐      ┌───────▼───┐
    │  GHCR    │      │ Docker Hub│
    │ (ghcr.io)│      │           │
    └──────────┘      └───────────┘
```

## 📊 Image Details

### Backend Image Layers

```dockerfile
FROM python:3.11-slim as builder
# Install dependencies
# Create wheels

FROM python:3.11-slim
# Copy wheels
# Install packages
# Copy application code
# Final size: ~150MB
```

### Multi-arch Manifest

```
NAME                                  DIGEST                                                                   SIZE      PLATFORMS
inventory-backend:latest             sha256:abc123...                                                         -         linux/amd64, linux/arm64
├── linux/amd64                      sha256:def456...                                                         145MB
└── linux/arm64                      sha256:ghi789...                                                         152MB
```

## ✅ Verification

### Check Image Details
```bash
# Inspect multi-arch manifest
docker buildx imagetools inspect ghcr.io/naidu72/inventory-backend:latest

# Output shows:
# - Supported platforms
# - Layer digests
# - Image sizes
```

### Pull and Test
```bash
# Pull for current architecture
docker pull ghcr.io/naidu72/inventory-backend:latest

# Run quick test
docker run --rm ghcr.io/naidu72/inventory-backend:latest python --version
```

### Test on Raspberry Pi
```bash
# On your Pi cluster
docker pull ghcr.io/naidu72/inventory-backend:latest

# Verify it pulled arm64 version
docker inspect ghcr.io/naidu72/inventory-backend:latest | grep Architecture
# Output: "Architecture": "arm64"
```

## 🔍 Troubleshooting

### Build Fails
```bash
# Check builder status
docker buildx ls

# Restart builder
docker buildx rm inventory-builder
docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use
docker buildx inspect --bootstrap
```

### Authentication Issues
```bash
# Re-authenticate to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin

# Re-authenticate to Docker Hub
docker login
```

### Push Fails
```bash
# Check registry connectivity
curl -I https://ghcr.io
curl -I https://hub.docker.com

# Verify authentication
docker system info | grep -A 5 "Registry"
```

## 📝 Environment Variables

For automated builds (CI/CD), set:

```bash
# GitHub Container Registry
export GITHUB_USERNAME=naidu72
export GITHUB_TOKEN=<your-token>

# Docker Hub
export DOCKERHUB_USERNAME=naidu72
export DOCKERHUB_TOKEN=<your-token>
```

## 🎯 Success Criteria

- [x] Multi-arch builder configured
- [x] Build scripts created and tested
- [ ] Images successfully built for amd64 and arm64
- [ ] Images pushed to GHCR
- [ ] Images pushed to Docker Hub
- [ ] Images verified on both architectures

## 📈 Next Steps (Phase 3)

After Phase 2 completion:
- Deploy to Kubernetes using Terraform
- Use these multi-arch images in K8s manifests
- Test on actual Raspberry Pi cluster

## 📚 Resources

- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Hub](https://docs.docker.com/docker-hub/)
- [Multi-platform Images](https://docs.docker.com/build/building/multi-platform/)
