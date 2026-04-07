# Setup Instructions - Manual Secrets Configuration

## 🔍 Issue Identified

The automated secrets setup script requires GitHub CLI access to the repository's secrets API. You encountered this error:

```
HTTP 403: You must have repository read permissions or have the repository 
secrets fine-grained permission.
```

**Cause:** 
- Repository is owned by `naidu72`
- You're authenticated as `naidug09` 
- Different accounts = no access to secrets API

## ✅ Solution: Manual Setup via GitHub Web UI

Use the GitHub web interface to add secrets manually. This is more reliable and doesn't require CLI permissions.

## 🚀 Quick Setup (3 Steps)

### Step 1: Get Your SSH Private Key

Run this helper script to display your SSH key:

```bash
cd /home/frontier/terraform/study_terraform
.github/show-ssh-key.sh
```

This will:
- ✅ Find your SSH key
- ✅ Test connection to Pi
- ✅ Display the key for copying
- ✅ Generate new key if needed

**Copy the entire output** (including `-----BEGIN` and `-----END` lines)

### Step 2: Add Secrets in GitHub

1. **Go to secrets page:**
   ```
   https://github.com/naidu72/study_terraform/settings/secrets/actions
   ```

2. **Add these 4 secrets** (click "New repository secret" for each):

   | Name | Value |
   |------|-------|
   | `AWS_ACCESS_KEY_ID` | `admin` |
   | `AWS_SECRET_ACCESS_KEY` | `password` |
   | `PI_HOST` | `pi` |
   | `PI_SSH_PRIVATE_KEY` | (paste your SSH key from Step 1) |

### Step 3: Push and Deploy

```bash
cd /home/frontier/terraform/study_terraform

# Add all files
git add .github/ CICD_README.md SETUP_INSTRUCTIONS.md

# Commit
git commit -m "Add GitHub Actions CI/CD pipeline with manual setup instructions"

# Push to trigger deployment
git push origin main
```

## 📊 Watch Deployment

**GitHub Web UI:**
```
https://github.com/naidu72/study_terraform/actions
```

**GitHub CLI (if accessible):**
```bash
gh run list --repo naidu72/study_terraform
gh run watch --repo naidu72/study_terraform
```

## 🔧 Detailed Instructions

If you need more detailed step-by-step instructions, see:

**[.github/SETUP_SECRETS_MANUAL.md](.github/SETUP_SECRETS_MANUAL.md)**

This includes:
- Detailed screenshots and explanations
- Troubleshooting for common issues
- Alternative setup methods
- SSH key generation guide

## 🧪 Test Before Pushing

### Test SSH Connection

```bash
ssh naidu@pi "echo 'SSH test successful'"
```

**Expected output:** `SSH test successful`

### Test MinIO Backend

```bash
curl http://localhost:9000/minio/health/live
```

**Expected output:** `200 OK` or similar

### Validate Terraform

```bash
cd /home/frontier/terraform/study_terraform
terraform init
terraform validate
```

**Expected output:** `Success! The configuration is valid.`

## 📋 Secrets Checklist

Before pushing to GitHub, verify you have:

- [ ] `AWS_ACCESS_KEY_ID` = `admin` (or your MinIO access key)
- [ ] `AWS_SECRET_ACCESS_KEY` = `password` (or your MinIO secret key)
- [ ] `PI_HOST` = `pi` (or your Pi's IP address)
- [ ] `PI_SSH_PRIVATE_KEY` = Your SSH private key (entire file content)

## 🎯 What Happens Next

After pushing to GitHub:

1. **GitHub Actions triggers** automatically
2. **Terraform plan runs** for both workspaces (pi & wsl)
3. **Terraform apply runs** if on main branch
4. **Resources deploy** to both Pi and WSL
5. **Artifacts saved** (plans, outputs)

## 📈 Expected Timeline

- **Secrets setup**: 2-3 minutes
- **Push to GitHub**: 30 seconds
- **Workflow execution**: 5-8 minutes
- **Total**: ~10 minutes to first deployment

## 🔍 Verification

After deployment completes, verify resources:

**On WSL:**
```bash
docker ps --filter "label=managed_by=terraform"
docker network ls --filter "label=managed_by=terraform"
```

**On Pi:**
```bash
ssh naidu@pi "docker ps --filter 'label=managed_by=terraform'"
ssh naidu@pi "docker network ls --filter 'label=managed_by=terraform'"
```

## 🆘 Troubleshooting

### Can't Access GitHub Secrets Page

**Issue:** 403 Forbidden when accessing secrets page

**Solution:**
- Ensure you're logged into GitHub as `naidu72` (repository owner)
- Or ask repository owner to add you as collaborator with write access
- Or fork repository to your account (`naidug09`)

### SSH Key Doesn't Work

**Issue:** Pipeline fails with SSH connection error

**Solution:**
```bash
# Generate new key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform_new -N ""

# Copy to Pi
ssh-copy-id -i ~/.ssh/pi_terraform_new.pub naidu@pi

# Test
ssh -i ~/.ssh/pi_terraform_new naidu@pi "echo 'Works!'"

# Display for GitHub
cat ~/.ssh/pi_terraform_new
```

### MinIO Not Accessible

**Issue:** Backend initialization fails

**Solution:**
```bash
# Check if MinIO is running
docker ps | grep minio

# Start MinIO if not running
docker run -d -p 9000:9000 -p 9001:9001 \
  --name minio \
  -v ~/minio/data:/data \
  minio/minio server /data --console-address ":9001"

# Create bucket
# Go to http://localhost:9001 and create bucket "tf-state"
```

## 📚 Additional Resources

| Document | Purpose |
|----------|---------|
| **CICD_README.md** | Quick reference guide |
| **.github/QUICKSTART.md** | 5-minute setup guide |
| **.github/SETUP_SECRETS_MANUAL.md** | Detailed manual setup |
| **.github/workflows/README.md** | Complete pipeline docs |
| **.github/MANUAL_DEPLOYMENT.md** | Manual deployment guide |

## 🎓 Alternative: Use Your Own Account

If you want to use your `naidug09` account:

### Fork the Repository

```bash
# Fork via GitHub CLI
gh repo fork naidu72/study_terraform --clone=false

# Update remote
cd /home/frontier/terraform/study_terraform
git remote set-url origin git@github.com:naidug09/study_terraform.git

# Push
git push origin main
```

Then set up secrets on your forked repository:
```
https://github.com/naidug09/study_terraform/settings/secrets/actions
```

## ✅ Success Indicators

You'll know everything is working when:

1. ✅ All 4 secrets appear in GitHub Settings
2. ✅ Push triggers workflow in Actions tab
3. ✅ Workflow shows "Terraform Plan" jobs running
4. ✅ Both workspaces (pi & wsl) plan successfully
5. ✅ Both workspaces apply successfully
6. ✅ Resources appear in `docker ps` on both hosts

## 🎉 Summary

**Problem:** Automated script can't access secrets API (different GitHub accounts)

**Solution:** Manual setup via GitHub web UI

**Steps:**
1. Run `.github/show-ssh-key.sh` to get SSH key
2. Add 4 secrets at https://github.com/naidu72/study_terraform/settings/secrets/actions
3. Push to GitHub and watch deployment

**Time:** ~10 minutes total

**Status:** Ready to deploy! 🚀

---

**Next Step:** Run `.github/show-ssh-key.sh` to get your SSH key
