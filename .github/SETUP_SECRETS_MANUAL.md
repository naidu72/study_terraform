# Manual Secrets Setup Guide

## Issue with Automated Script

The automated script (`.github/setup-secrets.sh`) requires GitHub CLI access to the repository's secrets API. If you encounter permission errors, use this manual setup guide instead.

## Prerequisites

- GitHub account with access to the repository
- Repository: `naidu72/study_terraform`
- Admin or write access to the repository

## Step-by-Step: Manual Secrets Setup via GitHub Web UI

### 1. Navigate to Repository Settings

1. Go to: https://github.com/naidu72/study_terraform
2. Click on **Settings** tab (top right)
3. In the left sidebar, click **Secrets and variables** → **Actions**

### 2. Add Required Secrets

You need to add 4 secrets. For each secret:

1. Click **New repository secret** button
2. Enter the **Name** (exactly as shown below)
3. Enter the **Value**
4. Click **Add secret**

---

### Secret 1: AWS_ACCESS_KEY_ID

**Name:** `AWS_ACCESS_KEY_ID`

**Value:** `admin`

**Purpose:** MinIO/S3 backend access key (matches your `backend.tf` configuration)

---

### Secret 2: AWS_SECRET_ACCESS_KEY

**Name:** `AWS_SECRET_ACCESS_KEY`

**Value:** `password`

**Purpose:** MinIO/S3 backend secret key (matches your `backend.tf` configuration)

---

### Secret 3: PI_HOST

**Name:** `PI_HOST`

**Value:** `pi` (or your Pi's IP address like `192.168.1.100`)

**Purpose:** Hostname or IP address of your Raspberry Pi

**How to find:**
```bash
# If using hostname
echo "pi"

# Or get IP address
ssh naidu@pi "hostname -I | awk '{print \$1}'"
```

---

### Secret 4: PI_SSH_PRIVATE_KEY

**Name:** `PI_SSH_PRIVATE_KEY`

**Value:** Your SSH private key content (entire file)

**Purpose:** SSH authentication to Raspberry Pi

**How to get the value:**

#### Option A: Use existing SSH key

```bash
# Display your SSH private key
cat ~/.ssh/id_rsa
```

Copy the **entire output** including the `-----BEGIN` and `-----END` lines.

**Example format:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
NhAAAAAwEAAQAAAYEAqK8xqKqJ... (many lines)
...
-----END OPENSSH PRIVATE KEY-----
```

#### Option B: Generate new dedicated key

```bash
# Generate new SSH key for Terraform
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform -N ""

# Copy public key to Pi
ssh-copy-id -i ~/.ssh/pi_terraform.pub naidu@pi

# Test connection
ssh -i ~/.ssh/pi_terraform naidu@pi "echo 'SSH works!'"

# Display private key for GitHub secret
cat ~/.ssh/pi_terraform
```

Copy the entire output and paste it as the secret value.

---

## 3. Verify Secrets

After adding all 4 secrets, you should see:

```
AWS_ACCESS_KEY_ID          Updated X minutes ago
AWS_SECRET_ACCESS_KEY      Updated X minutes ago
PI_HOST                    Updated X minutes ago
PI_SSH_PRIVATE_KEY         Updated X minutes ago
```

## 4. Test the Pipeline

### Push to GitHub

```bash
cd /home/frontier/terraform/study_terraform

# Add all pipeline files
git add .github/ CICD_README.md

# Commit
git commit -m "Add GitHub Actions CI/CD pipeline"

# Push to trigger the workflow
git push origin main
```

### Watch the Workflow

**Option 1: GitHub Web UI**
1. Go to https://github.com/naidu72/study_terraform/actions
2. You should see "Terraform Multi-Workspace Deployment" running
3. Click on it to watch progress

**Option 2: GitHub CLI (if accessible)**
```bash
gh run list --repo naidu72/study_terraform --limit 1
gh run watch --repo naidu72/study_terraform
```

## Troubleshooting

### Issue: Can't find Settings tab

**Cause:** You don't have admin/write access to the repository

**Solution:** 
- Ask the repository owner to add you as a collaborator with write access
- Or fork the repository to your own account (`naidug09`)

### Issue: SSH key doesn't work

**Test SSH connection:**
```bash
ssh naidu@pi "echo 'SSH test successful'"
```

**If fails:**
1. Check Pi is powered on and connected to network
2. Verify SSH service is running on Pi
3. Check firewall allows SSH (port 22)
4. Verify username is correct (`naidu`)

**Generate new key and try again:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform_new -N ""
ssh-copy-id -i ~/.ssh/pi_terraform_new.pub naidu@pi
ssh -i ~/.ssh/pi_terraform_new naidu@pi "echo 'Works!'"
```

### Issue: MinIO credentials don't work

**Check your backend.tf:**
```bash
grep -A 5 "access_key\|secret_key" /home/frontier/terraform/study_terraform/backend.tf
```

**Update secrets to match:**
- If `backend.tf` shows different credentials, use those values
- Default values are `admin` / `password`

### Issue: Workflow fails with "Backend initialization failed"

**Cause:** MinIO/S3 backend not accessible from GitHub Actions

**Solution:**
You have two options:

#### Option A: Use public S3-compatible backend

If your MinIO is not publicly accessible, consider:
1. AWS S3 (requires AWS account)
2. Terraform Cloud (free tier available)
3. Publicly accessible MinIO instance

#### Option B: Use local backend for GitHub Actions

Create a separate backend configuration for CI/CD:

```bash
# Create CI-specific backend config
cat > /home/frontier/terraform/study_terraform/backend-ci.tf << 'EOF'
# CI/CD uses local backend (state stored in workspace)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF

# Update workflow to use local backend
# (Requires modifying .github/workflows/terraform.yml)
```

## Alternative: Use Different GitHub Account

If the repository is under `naidu72` but you're authenticated as `naidug09`:

### Option 1: Authenticate as naidu72

```bash
# Logout current account
gh auth logout

# Login as naidu72
gh auth login
# Follow prompts and authenticate as naidu72
```

### Option 2: Fork to your account

```bash
# Fork the repository to naidug09
gh repo fork naidu72/study_terraform --clone=false

# Update your remote
cd /home/frontier/terraform/study_terraform
git remote set-url origin git@github.com:naidug09/study_terraform.git
git push origin main
```

Then set up secrets on your forked repository.

## Quick Verification Checklist

Before first deployment:

- [ ] All 4 secrets added in GitHub Settings
- [ ] SSH key can connect to Pi: `ssh naidu@pi "echo test"`
- [ ] MinIO is running: `curl http://localhost:9000/minio/health/live`
- [ ] Pipeline files committed and pushed
- [ ] Workflow appears in Actions tab

## Next Steps

After secrets are configured:

1. **Push to GitHub** (if not already done)
   ```bash
   git push origin main
   ```

2. **Monitor first run**
   - Go to: https://github.com/naidu72/study_terraform/actions
   - Watch the workflow execution
   - Check for any errors

3. **Verify deployment**
   ```bash
   # Check WSL
   docker ps --filter "label=managed_by=terraform"
   
   # Check Pi
   ssh naidu@pi "docker ps --filter 'label=managed_by=terraform'"
   ```

## Getting Help

If you encounter issues:

1. **Check workflow logs** in GitHub Actions tab
2. **Review secret names** - they must match exactly
3. **Test SSH manually** before using in pipeline
4. **Verify backend access** - MinIO must be accessible

## Summary

Manual secret setup via GitHub Web UI:
1. ✅ Go to repository Settings → Secrets and variables → Actions
2. ✅ Add 4 secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, PI_HOST, PI_SSH_PRIVATE_KEY
3. ✅ Push pipeline files to GitHub
4. ✅ Watch workflow run in Actions tab

**Direct link to secrets page:**
https://github.com/naidu72/study_terraform/settings/secrets/actions
