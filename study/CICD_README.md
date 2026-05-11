# CI/CD Pipeline - Quick Reference

## 🎯 What's New

A complete GitHub Actions CI/CD pipeline has been added to automate Terraform deployments across your two workspaces: **pi** and **wsl**.

## 📁 New Files

```
.github/
├── workflows/
│   ├── terraform.yml          # Main pipeline (8.3 KB)
│   └── README.md              # Pipeline docs (6.7 KB)
├── QUICKSTART.md              # 5-min setup (7.5 KB)
├── MANUAL_DEPLOYMENT.md       # Manual guide (7.5 KB)
├── PIPELINE_SUMMARY.md        # Architecture (11 KB)
├── FILES_CREATED.md           # File summary (8.1 KB)
└── setup-secrets.sh           # Setup script (3.3 KB)
```

## 🚀 Quick Start (5 Minutes)

### Step 1: Configure Secrets
```bash
cd /home/frontier/terraform/study_terraform
.github/setup-secrets.sh
```

### Step 2: Push to GitHub
```bash
git add .github/ CICD_README.md
git commit -m "Add GitHub Actions CI/CD pipeline"
git push origin main
```

### Step 3: Watch Deployment
Go to GitHub Actions tab and watch your infrastructure deploy automatically!

## ✨ What It Does

### Automatic Deployments
- **Push to main** → Plans and applies to both workspaces
- **Push to develop** → Plans both workspaces (no apply)
- **Pull Request** → Plans and comments results on PR

### Manual Control
- **Workflow Dispatch** → Choose workspace (pi/wsl/both) and action (plan/apply/destroy)
- **Selective Deployment** → Deploy to one workspace at a time
- **Safe Destruction** → Remove infrastructure with approval gates

## 🔐 Required Secrets

Configure these in GitHub Settings → Secrets and variables → Actions:

| Secret | Value | Purpose |
|--------|-------|---------|
| `AWS_ACCESS_KEY_ID` | `admin` | MinIO/S3 backend access |
| `AWS_SECRET_ACCESS_KEY` | `password` | MinIO/S3 backend secret |
| `PI_SSH_PRIVATE_KEY` | Your private key | SSH access to Pi |
| `PI_HOST` | `pi` or IP | Pi hostname |

## 📚 Documentation

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[QUICKSTART.md](.github/QUICKSTART.md)** | Get started in 5 minutes | First time setup |
| **[workflows/README.md](.github/workflows/README.md)** | Complete reference | Understanding features |
| **[MANUAL_DEPLOYMENT.md](.github/MANUAL_DEPLOYMENT.md)** | Manual deployment guide | Manual operations |
| **[PIPELINE_SUMMARY.md](.github/PIPELINE_SUMMARY.md)** | Architecture details | Deep dive |
| **[FILES_CREATED.md](.github/FILES_CREATED.md)** | What was created | Overview |

## 🎮 Common Commands

```bash
# Setup secrets interactively
.github/setup-secrets.sh

# View workflow runs
gh run list --workflow=terraform.yml

# Watch latest run
gh run watch

# View detailed logs
gh run view --log

# Manual deployment (plan only)
gh workflow run terraform.yml -f workspace=both -f action=plan

# Manual deployment (apply to wsl)
gh workflow run terraform.yml -f workspace=wsl -f action=apply
```

## 🏗️ Pipeline Architecture

```
Push to main
     ↓
┌────────────────────┐
│  Terraform Plan    │
│  ├─ pi workspace   │  (Parallel)
│  └─ wsl workspace  │
└────────────────────┘
     ↓
┌────────────────────┐
│  Terraform Apply   │
│  ├─ pi workspace   │  (Sequential)
│  └─ wsl workspace  │
└────────────────────┘
     ↓
   Success!
```

## 🔍 Monitoring

### View in GitHub
1. Go to **Actions** tab
2. Click on workflow run
3. Expand jobs to see details
4. Download artifacts (plans, outputs)

### View via CLI
```bash
# List recent runs
gh run list --workflow=terraform.yml --limit 5

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

## 🛡️ Safety Features

- ✅ **Plan before apply** - Always review changes first
- ✅ **Sequential deployment** - One workspace at a time
- ✅ **Artifact storage** - Plans saved for audit
- ✅ **PR integration** - See changes before merge
- ✅ **Environment protection** - Optional approval gates
- ✅ **Manual controls** - Override automatic behavior

## 🎯 Workflow Triggers

| Trigger | Plan | Apply | Workspaces |
|---------|------|-------|------------|
| Push to main | ✅ | ✅ | Both |
| Push to develop | ✅ | ❌ | Both |
| Pull Request | ✅ | ❌ | Both |
| Manual (plan) | ✅ | ❌ | Selected |
| Manual (apply) | ✅ | ✅ | Selected |
| Manual (destroy) | ❌ | ❌ (destroy) | Selected |

## 🔧 Troubleshooting

### Pipeline Fails on First Run

**Check secrets:**
```bash
gh secret list
```

**Expected output:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
PI_HOST
PI_SSH_PRIVATE_KEY
```

### Can't Connect to Pi

**Test SSH manually:**
```bash
ssh naidu@pi "echo 'SSH works!'"
```

**If fails, regenerate key:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform
ssh-copy-id -i ~/.ssh/pi_terraform.pub naidu@pi
cat ~/.ssh/pi_terraform | gh secret set PI_SSH_PRIVATE_KEY
```

### Backend Initialization Fails

**Check MinIO is running:**
```bash
curl http://localhost:9000/minio/health/live
```

**Start MinIO if needed:**
```bash
docker run -d -p 9000:9000 -p 9001:9001 \
  --name minio \
  -v ~/minio/data:/data \
  minio/minio server /data --console-address ":9001"
```

## 📊 Success Indicators

After first deployment, you should see:

✅ Workflow run completes successfully
✅ Both workspaces show "Apply complete"
✅ Artifacts uploaded (plans, outputs)
✅ Resources deployed on both Pi and WSL

**Verify deployments:**
```bash
# Check WSL
docker ps --filter "label=managed_by=terraform"

# Check Pi
ssh naidu@pi "docker ps --filter 'label=managed_by=terraform'"
```

## 🎓 Next Steps

1. **Configure secrets** - Run `.github/setup-secrets.sh`
2. **Push to GitHub** - Commit and push the pipeline files
3. **Watch first deployment** - Go to Actions tab
4. **Test manual deployment** - Try workflow dispatch
5. **Create a PR** - Test PR workflow with plan comments

## 💡 Pro Tips

- **Always plan first** - Review changes before applying
- **Test in WSL** - Use as staging before Pi
- **Use PR workflow** - Get plan feedback before merge
- **Monitor logs** - Check Actions tab regularly
- **Keep backups** - Download state files periodically

## 🆘 Getting Help

1. **Read docs** - Start with QUICKSTART.md
2. **Check logs** - View workflow run details
3. **Test locally** - Run terraform commands manually
4. **Verify secrets** - Ensure all 4 secrets are set

## 📞 Quick Links

- **Setup Guide**: [.github/QUICKSTART.md](.github/QUICKSTART.md)
- **Pipeline Docs**: [.github/workflows/README.md](.github/workflows/README.md)
- **Manual Guide**: [.github/MANUAL_DEPLOYMENT.md](.github/MANUAL_DEPLOYMENT.md)
- **Architecture**: [.github/PIPELINE_SUMMARY.md](.github/PIPELINE_SUMMARY.md)

---

**Status**: ✅ Pipeline created and ready
**Next Step**: Run `.github/setup-secrets.sh` to configure secrets
**Time to Deploy**: ~5 minutes after configuration

Happy deploying! 🚀
