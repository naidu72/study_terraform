# Phase 2 - Multi-arch Docker Builds & Registry Push

## 🎯 Goals

1. Build Docker images for both **amd64** (x86_64) and **arm64** (for Raspberry Pi)
2. Push images to **GitHub Container Registry** (ghcr.io)
3. Push images to **Docker Hub**
4. Optimize image sizes
5. Set up build scripts for automation

## 📋 Prerequisites

### 1. Docker Buildx (Multi-arch builder)
```bash
# Check if buildx is available
docker buildx version

# Create a new builder instance
docker buildx create --name multiarch --use

# Inspect and bootstrap the builder
docker buildx inspect --bootstrap
```

### 2. Registry Authentication

#### GitHub Container Registry (ghcr.io)
```bash
# Create GitHub Personal Access Token with:
# - read:packages
# - write:packages
# - delete:packages

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

#### Docker Hub
```bash
# Login to Docker Hub
docker login
# Enter username and password
```

## 🏗️ Build Strategy

### Image Naming Convention

```
# GitHub Container Registry
ghcr.io/naidu72/inventory-backend:latest
ghcr.io/naidu72/inventory-backend:v1.0.0
ghcr.io/naidu72/inventory-frontend:latest
ghcr.io/naidu72/inventory-frontend:v1.0.0

# Docker Hub
naidu72/inventory-backend:latest
naidu72/inventory-backend:v1.0.0
naidu72/inventory-frontend:latest
naidu72/inventory-frontend:v1.0.0
```

### Multi-arch Platforms
- `linux/amd64` - For development, CI/CD
- `linux/arm64` - For Raspberry Pi cluster

## 📦 Phase 2 Implementation Steps

### Step 1: Setup Docker Buildx
Create multi-platform builder

### Step 2: Optimize Dockerfiles
Review and optimize for multi-arch

### Step 3: Build Script
Create automated build script

### Step 4: Test Locally
Verify images work on both architectures

### Step 5: Push to Registries
Push to both GHCR and Docker Hub

### Step 6: Verify on Pi
Pull and test on Raspberry Pi cluster

## 🔧 What We'll Create

```
inventory-manager/
├── scripts/
│   ├── build-multiarch.sh        # Build multi-arch images
│   ├── push-registries.sh        # Push to both registries
│   └── test-images.sh            # Test images
│
├── app/
│   ├── backend/
│   │   └── Dockerfile            # ✅ Already optimized
│   └── frontend/
│       └── Dockerfile            # To be created
│
└── docs/
    └── PHASE2_COMPLETE.md        # Phase 2 summary
```

## ⏱️ Estimated Time

- Setup: 10 minutes
- Build scripts: 15 minutes
- First build: 20-30 minutes (downloads base images)
- Testing: 10 minutes
- **Total: ~1 hour**

## 🚀 Let's Begin!

Ready to start? I'll guide you through each step!
