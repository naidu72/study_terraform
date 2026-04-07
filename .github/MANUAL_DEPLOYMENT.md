# Manual Deployment Guide

This guide shows you how to manually trigger Terraform deployments for specific workspaces.

## Quick Reference

| Action | When to Use | Risk Level |
|--------|-------------|------------|
| Plan | Test changes without applying | ✅ Safe |
| Apply | Deploy infrastructure changes | ⚠️ Moderate |
| Destroy | Remove all infrastructure | 🔴 High |

## Step-by-Step: Manual Workflow Dispatch

### 1. Navigate to Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **Terraform Multi-Workspace Deployment** from the left sidebar

### 2. Run Workflow

1. Click the **Run workflow** dropdown (top right)
2. You'll see three options:

#### Option 1: Workspace Selection
```
Workspace to deploy (pi, wsl, or both)
├── both    ← Deploy to both workspaces (default)
├── pi      ← Deploy only to Raspberry Pi
└── wsl     ← Deploy only to WSL environment
```

#### Option 2: Action Selection
```
Terraform action
├── plan    ← Preview changes without applying (default)
├── apply   ← Apply infrastructure changes
└── destroy ← Remove all infrastructure
```

#### Option 3: Branch
```
Use workflow from: main (or select another branch)
```

3. Click **Run workflow** button

## Common Scenarios

### Scenario 1: Test Changes Before Deploying

**Goal**: See what Terraform will change without actually applying

```
Workspace: both
Action: plan
Branch: main
```

**Result**: 
- Runs `terraform plan` for both workspaces
- Shows what would change
- Does NOT apply any changes
- Safe to run anytime

### Scenario 2: Deploy to Single Workspace

**Goal**: Apply changes only to WSL environment

```
Workspace: wsl
Action: apply
Branch: main
```

**Result**:
- Runs plan for WSL workspace
- Applies changes to WSL only
- Pi workspace unchanged

### Scenario 3: Deploy to All Workspaces

**Goal**: Apply changes to both Pi and WSL

```
Workspace: both
Action: apply
Branch: main
```

**Result**:
- Runs plan for both workspaces
- Applies changes sequentially (Pi first, then WSL)
- Both environments updated

### Scenario 4: Destroy Infrastructure (Careful!)

**Goal**: Remove all infrastructure from Pi

```
Workspace: pi
Action: destroy
Branch: main
```

**Result**:
- Destroys all Terraform-managed resources on Pi
- Requires environment approval (if configured)
- ⚠️ **CANNOT BE UNDONE**

## Monitoring Workflow Runs

### View Progress

1. After triggering, you'll see the workflow run appear
2. Click on the run to see details
3. Expand jobs to see individual workspace deployments

### Check Logs

```
Workflow Run
├── terraform-plan (pi)
│   ├── Checkout code
│   ├── Setup Terraform
│   ├── Terraform Init
│   ├── Select Workspace
│   ├── Terraform Validate
│   └── Terraform Plan
├── terraform-plan (wsl)
│   └── (same steps)
└── terraform-apply (pi)
    └── (if action=apply)
```

### Download Artifacts

After workflow completes:
1. Scroll to bottom of workflow run page
2. See **Artifacts** section
3. Download:
   - `tfplan-pi` - Terraform plan for Pi
   - `tfplan-wsl` - Terraform plan for WSL
   - `outputs-pi` - Terraform outputs (after apply)
   - `outputs-wsl` - Terraform outputs (after apply)

## Troubleshooting

### Workflow Doesn't Appear

**Problem**: Can't see "Run workflow" button

**Solution**: 
- Ensure workflow file is on the branch you're viewing
- Check you have write access to the repository
- Refresh the page

### Plan Succeeds but Apply Fails

**Problem**: Plan works but apply fails

**Common Causes**:
1. **State lock**: Another process is using the state
   - Wait for other operations to complete
   
2. **Connectivity**: Can't reach Docker host
   - Check Pi is online (for pi workspace)
   - Verify SSH key is correct
   
3. **Resource conflict**: Resource already exists
   - Check if resources were manually created
   - Review state file

### SSH Connection Failed (Pi Workspace)

**Problem**: Can't connect to Pi

**Checklist**:
- [ ] Pi is powered on and connected to network
- [ ] `PI_HOST` secret is correct hostname/IP
- [ ] `PI_SSH_PRIVATE_KEY` secret contains valid private key
- [ ] Public key is in Pi's `~/.ssh/authorized_keys`
- [ ] Pi allows SSH connections (port 22 open)

**Test SSH manually**:
```bash
ssh -i ~/.ssh/your-key naidu@pi
```

### Backend Initialization Failed

**Problem**: Can't initialize Terraform backend

**Checklist**:
- [ ] MinIO/S3 service is running
- [ ] Bucket `tf-state` exists
- [ ] `AWS_ACCESS_KEY_ID` secret is correct
- [ ] `AWS_SECRET_ACCESS_KEY` secret is correct
- [ ] Backend endpoint is accessible

**Test backend manually**:
```bash
terraform init
```

## Best Practices

### 1. Always Plan First

Before applying changes:
```
Step 1: Run with action=plan
Step 2: Review the plan output
Step 3: If looks good, run with action=apply
```

### 2. Deploy One Workspace at a Time

For critical changes:
```
Step 1: Deploy to wsl (test environment)
Step 2: Verify everything works
Step 3: Deploy to pi (if wsl succeeded)
```

### 3. Use Feature Branches

For testing:
```
Step 1: Create feature branch
Step 2: Make changes
Step 3: Run workflow on feature branch with action=plan
Step 4: Review plan
Step 5: Merge to main for automatic deployment
```

### 4. Keep Backups

Before major changes:
```bash
# Export current state
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Or download from S3/MinIO
aws s3 cp s3://tf-state/phase1-project/terraform.tfstate backup.tfstate
```

## Emergency Procedures

### Rollback Changes

If something goes wrong after apply:

1. **Option A: Revert Git Commit**
   ```bash
   git revert HEAD
   git push origin main
   # Workflow will auto-deploy previous state
   ```

2. **Option B: Manual Terraform**
   ```bash
   # SSH to affected host
   cd /path/to/terraform
   terraform workspace select <workspace>
   terraform apply -var-file=<workspace>.tfvars
   ```

### Force Unlock State

If state is locked:

```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>
```

### Recover from Failed Destroy

If destroy fails partway:

1. Check what resources remain:
   ```bash
   terraform state list
   ```

2. Manually remove stuck resources:
   ```bash
   terraform state rm <resource>
   ```

3. Re-run destroy

## Security Notes

### Secrets Rotation

Rotate secrets regularly:

```bash
# Generate new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform_new

# Update GitHub secret
gh secret set PI_SSH_PRIVATE_KEY < ~/.ssh/pi_terraform_new

# Update Pi authorized_keys
ssh-copy-id -i ~/.ssh/pi_terraform_new.pub naidu@pi
```

### Audit Trail

All deployments are logged:
- GitHub Actions logs (retained per your settings)
- Terraform state history (in backend)
- Git commit history

Review regularly:
```bash
# View recent workflow runs
gh run list --workflow=terraform.yml

# View specific run
gh run view <run-id>
```

## Getting Help

If you encounter issues:

1. **Check workflow logs**: Detailed error messages in Actions tab
2. **Review plan output**: See what Terraform is trying to do
3. **Test locally**: Run terraform commands on your machine
4. **Check secrets**: Verify all required secrets are set correctly

## Quick Command Reference

```bash
# List workflow runs
gh run list --workflow=terraform.yml

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>

# View workflow file
gh workflow view terraform.yml

# List secrets (names only)
gh secret list

# Set a secret
gh secret set SECRET_NAME

# Delete a secret
gh secret delete SECRET_NAME
```
