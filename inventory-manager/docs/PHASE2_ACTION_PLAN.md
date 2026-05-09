# 🎯 Phase 2 - Your 3-Step Action Plan

## Current Situation

✅ **Setup Complete!** All tools, scripts, and documentation are ready.  
⏳ **Waiting on:** GitHub Container Registry authentication  
🎯 **Goal:** Build multi-arch images for your Pi cluster

---

## Step 1: Get GitHub Token (2 minutes)

### 1.1 Create Token
Open: https://github.com/settings/tokens/new

### 1.2 Configure Token
- **Name**: `inventory-manager-ghcr`
- **Expiration**: 90 days (or custom)
- **Select scopes**:
  - ✅ `read:packages`
  - ✅ `write:packages`
  - ✅ `delete:packages` (optional)

### 1.3 Generate and Copy
Click "Generate token" → Copy the token immediately!

It looks like: `ghp_xxxxxxxxxxxxxxxxxxxx`

---

## Step 2: Authenticate (1 minute)

Open your terminal and run:

```bash
# Set your token
export GITHUB_TOKEN=ghp_paste_your_token_here

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin
```

**Expected output:**
```
Login Succeeded
```

### Verify Authentication

```bash
cat ~/.docker/config.json | jq '.auths."ghcr.io"'
```

You should see your auth config.

---

## Step 3: Build Multi-arch Images (10-15 minutes)

```bash
# Navigate to project
cd /home/frontier/terraform/study_terraform/inventory-manager

# Run the build
./scripts/build-multiarch.sh
```

### What Happens

```
======================================
Multi-arch Docker Build - Inventory Manager
======================================

Version: latest
Platforms: linux/amd64,linux/arm64
Builder: inventory-builder

======================================
Building: backend
======================================
Building for platforms: linux/amd64,linux/arm64
GHCR: ghcr.io/naidu72/inventory-backend:latest
Docker Hub: naidu72/inventory-backend:latest

[+] Building 245.3s (28/28) FINISHED
...
✓ Successfully built and pushed: backend
  GHCR: ghcr.io/naidu72/inventory-backend:latest
  Docker Hub: naidu72/inventory-backend:latest

======================================
Build Summary
======================================

Version: latest
Platforms: linux/amd64,linux/arm64

Images pushed to:
  • GitHub Container Registry (ghcr.io)
  • Docker Hub

✓ All builds completed successfully!
```

### First Build Time
- **Expected**: 10-15 minutes
- **Why**: Downloads Python base images, installs dependencies
- **Next builds**: 3-5 minutes (cached!)

---

## Step 4: Test Images (2 minutes)

```bash
./scripts/test-images.sh latest ghcr.io naidu72
```

**Expected output:**
```
======================================
Testing Multi-arch Images
======================================

Registry: ghcr.io
Username: naidu72
Version: latest

======================================
Testing Backend Image
======================================

Inspecting image...
Name:      ghcr.io/naidu72/inventory-backend:latest
MediaType: application/vnd.oci.image.index.v1+json
Manifest:  sha256:abc123...

Manifests:
  Name:      ghcr.io/naidu72/inventory-backend:latest@sha256:def456...
  Platform:  linux/amd64
  
  Name:      ghcr.io/naidu72/inventory-backend:latest@sha256:ghi789...
  Platform:  linux/arm64

✓ Image inspection successful
✓ Image pulled successfully

======================================
Test Summary
======================================

✓ Image tests completed

Images are ready to deploy!
```

---

## ✅ Phase 2 Complete!

### What You Now Have

```
✅ Multi-arch images built
✅ Images pushed to GHCR
✅ Tested and verified
✅ Ready for Kubernetes deployment

Your images:
  ghcr.io/naidu72/inventory-backend:latest
  │
  ├─ linux/amd64 (~150MB)
  └─ linux/arm64 (~152MB)
```

### Next: Phase 3 - Terraform

Deploy these images to your Raspberry Pi Kubernetes cluster!

---

## Quick Command Summary

```bash
# 1. Authenticate (one-time)
export GITHUB_TOKEN=ghp_your_token
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin

# 2. Build
cd /home/frontier/terraform/study_terraform/inventory-manager
./scripts/build-multiarch.sh

# 3. Test
./scripts/test-images.sh latest ghcr.io naidu72

# Done! Ready for Phase 3
```

---

## Troubleshooting

### Build Fails?

Check builder:
```bash
docker buildx ls
docker buildx inspect inventory-builder
```

Recreate if needed:
```bash
docker buildx rm inventory-builder
docker buildx create --name inventory-builder --platform linux/amd64,linux/arm64 --use
docker buildx inspect --bootstrap
```

### Authentication Issues?

Re-authenticate:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin
```

Check token scopes: https://github.com/settings/tokens

### Push Fails?

Verify token has `write:packages` scope.

Check network:
```bash
curl -I https://ghcr.io
```

---

## Documentation

- **Full Guide**: `docs/PHASE2_README.md`
- **Status**: `docs/PHASE2_STATUS.md`
- **Quick Ref**: `docs/PHASE2_QUICKREF.md`
- **This Guide**: `docs/PHASE2_ACTION_PLAN.md`

---

## Timeline

| Step | Time | What |
|------|------|------|
| 1. Get Token | 2 min | GitHub settings |
| 2. Authenticate | 1 min | Docker login |
| 3. Build | 10-15 min | First build |
| 4. Test | 2 min | Verification |
| **Total** | **15-20 min** | **Phase 2 Complete!** |

---

**🎉 You're Ready! Let's complete Phase 2!** 🚀
