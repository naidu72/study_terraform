# Authentication Guide for Phase 2

## Current Status
You're currently authenticated to:
- AWS ECR (332728166114.dkr.ecr.us-east-1.amazonaws.com)
- AWS ECR (344760941228.dkr.ecr.us-east-1.amazonaws.com)  
- JFrog (hansentech.jfrog.io)

## 🔑 Required: Authenticate to Docker Registries

### Option 1: GitHub Container Registry (Recommended for Pi cluster)

**Step 1: Create GitHub Personal Access Token**
1. Go to: https://github.com/settings/tokens/new
2. Token name: `inventory-manager-ghcr`
3. Select scopes:
   - ✅ `read:packages`
   - ✅ `write:packages`
   - ✅ `delete:packages` (optional, for cleanup)
4. Click "Generate token"
5. **Copy the token immediately** (you won't see it again!)

**Step 2: Login to GHCR**
```bash
# Set your token as environment variable
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx

# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u naidu72 --password-stdin
```

**Verify:**
```bash
cat ~/.docker/config.json | jq '.auths."ghcr.io"'
```

### Option 2: Docker Hub (Alternative/Additional)

**Step 1: Login**
```bash
docker login
# Username: naidu72
# Password: <your-docker-hub-password>
```

**Step 2: Verify**
```bash
cat ~/.docker/config.json | jq '.auths."https://index.docker.io/v1/"'
```

## 🚀 Once Authenticated

### Build and Push to Both Registries
```bash
cd /home/frontier/terraform/study_terraform/inventory-manager

# Build multi-arch images and push
./scripts/build-multiarch.sh
```

### Or Build Specific Version
```bash
./scripts/build-multiarch.sh v1.0.0
```

## 📦 What Will Happen

The build script will:
1. ✅ Use the `inventory-builder` multi-arch builder
2. ✅ Build for `linux/amd64` and `linux/arm64`
3. ✅ Tag images for both registries:
   - `ghcr.io/naidu72/inventory-backend:latest`
   - `naidu72/inventory-backend:latest`
4. ✅ Push to both registries simultaneously
5. ✅ Display summary with image URLs

## 🎯 Recommendation

For your Pi cluster project, I recommend:
- **Primary**: Use GHCR (ghcr.io)
  - Free for public repos
  - Better for personal/team projects
  - Integrates with GitHub Actions
  
- **Secondary**: Use Docker Hub (optional)
  - Good for broader distribution
  - Has rate limits on free tier
  - Well-known registry

You can push to both, but for ArgoCD/Kubernetes deployments, we'll primarily use GHCR.

## 🔐 Security Note

The authentication will be stored in `~/.docker/config.json`. The build script will automatically use these credentials when pushing images.

## ✅ Ready to Proceed?

Once you've authenticated to at least one registry (GHCR recommended), we can start the build process!

Let me know when you're ready, or if you'd like me to help with the authentication steps.
