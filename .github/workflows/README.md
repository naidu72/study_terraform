# Terraform Multi-Workspace GitHub Actions Pipeline

This GitHub Actions pipeline automates Terraform deployments across two workspaces: `pi` and `wsl`.

## Features

- **Multi-workspace support**: Deploys to both `pi` and `wsl` workspaces
- **Automated planning**: Runs `terraform plan` on every push and PR
- **Controlled deployment**: Applies changes only on main branch or manual trigger
- **PR comments**: Automatically comments plan results on pull requests
- **Manual controls**: Workflow dispatch for selective workspace deployment
- **Destroy capability**: Safe infrastructure teardown with manual approval
- **Artifact storage**: Saves plans and outputs for auditing

## Workflow Triggers

### Automatic Triggers
- **Push to main/develop**: Runs plan for both workspaces, applies on main
- **Pull Request**: Runs plan and comments results on PR

### Manual Trigger (workflow_dispatch)
- **Workspace selection**: Choose `pi`, `wsl`, or `both`
- **Action selection**: Choose `plan`, `apply`, or `destroy`

## Required GitHub Secrets

Configure these secrets in your repository settings (Settings → Secrets and variables → Actions):

### S3 Backend Credentials (MinIO)
```
AWS_ACCESS_KEY_ID=admin
AWS_SECRET_ACCESS_KEY=password
```

### Pi SSH Access (for pi workspace)
```
PI_SSH_PRIVATE_KEY=<your-private-key-content>
PI_HOST=<pi-hostname-or-ip>
```

## Setting Up Secrets

### 1. S3/MinIO Backend Credentials

If using MinIO as shown in your `backend.tf`:

```bash
# These match your backend.tf configuration
AWS_ACCESS_KEY_ID: admin
AWS_SECRET_ACCESS_KEY: password
```

### 2. Pi SSH Private Key

Generate or use existing SSH key for Pi access:

```bash
# Generate new key (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform -N ""

# Copy public key to Pi
ssh-copy-id -i ~/.ssh/pi_terraform.pub naidu@pi

# Get private key content for GitHub secret
cat ~/.ssh/pi_terraform
```

Add the entire private key content (including `-----BEGIN` and `-----END` lines) to the `PI_SSH_PRIVATE_KEY` secret.

### 3. Pi Host

```
PI_HOST=pi  # or IP address like 192.168.1.100
```

## GitHub Environments (Optional but Recommended)

Create environments for deployment protection:

1. Go to Settings → Environments
2. Create environments: `pi`, `wsl`, `pi-destroy`, `wsl-destroy`
3. Add protection rules:
   - Required reviewers for production
   - Wait timer before deployment
   - Restrict to specific branches

## Workflow Jobs

### 1. terraform-plan
- Runs on: All pushes, PRs, and manual triggers
- Matrix strategy: Runs for both workspaces in parallel
- Outputs: Plan artifacts uploaded for apply job

### 2. terraform-apply
- Runs on: Push to main or manual trigger with action=apply
- Matrix strategy: Deploys workspaces sequentially (max-parallel: 1)
- Requires: terraform-plan job success
- Uses: Plan artifacts from previous job

### 3. terraform-destroy
- Runs on: Manual trigger with action=destroy only
- Matrix strategy: Destroys workspaces sequentially
- Requires: Manual approval via GitHub environment

## Usage Examples

### Automatic Deployment (Push to Main)

```bash
git add .
git commit -m "Update infrastructure"
git push origin main
```

This will:
1. Run `terraform plan` for both workspaces
2. Automatically apply changes if on main branch

### Manual Deployment (Specific Workspace)

1. Go to Actions tab in GitHub
2. Select "Terraform Multi-Workspace Deployment"
3. Click "Run workflow"
4. Select:
   - Workspace: `pi` (or `wsl` or `both`)
   - Action: `apply`
5. Click "Run workflow"

### Testing Changes (Pull Request)

```bash
git checkout -b feature/new-service
# Make changes
git add .
git commit -m "Add new service"
git push origin feature/new-service
# Create PR on GitHub
```

The pipeline will:
1. Run `terraform plan` for both workspaces
2. Comment the plan results on your PR
3. Not apply changes (only plan)

### Destroying Infrastructure

1. Go to Actions tab
2. Select "Terraform Multi-Workspace Deployment"
3. Click "Run workflow"
4. Select:
   - Workspace: `pi` (or specific workspace)
   - Action: `destroy`
5. Click "Run workflow"
6. Approve the destruction in the environment (if configured)

## Workspace Configuration

Each workspace uses its own tfvars file:

- `pi.tfvars`: Configuration for Raspberry Pi
- `wsl.tfvars`: Configuration for WSL environment

The pipeline automatically selects the correct tfvars file based on the workspace.

## Backend State Management

The pipeline uses S3 (MinIO) backend configured in `backend.tf`:

- Bucket: `tf-state`
- Key pattern: `phase1-project/terraform.tfstate`
- Endpoint: `http://localhost:9000` (adjust if needed)

Each workspace maintains separate state files in the backend.

## Troubleshooting

### SSH Connection to Pi Fails

Check:
1. `PI_SSH_PRIVATE_KEY` secret is correctly formatted
2. `PI_HOST` is reachable from GitHub Actions runners
3. Public key is in Pi's `~/.ssh/authorized_keys`
4. Pi allows SSH connections

### Backend Initialization Fails

Check:
1. MinIO/S3 endpoint is accessible
2. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
3. Bucket `tf-state` exists

### Plan/Apply Fails

Check:
1. Terraform syntax is valid (`terraform validate`)
2. Required variables are defined in tfvars files
3. Docker hosts are accessible (WSL socket, Pi SSH)

## Security Best Practices

1. **Never commit secrets**: Use GitHub Secrets for sensitive data
2. **Use environment protection**: Require approvals for production
3. **Review plans**: Always review plan output before applying
4. **Limit permissions**: Use minimal IAM/credentials required
5. **Rotate credentials**: Regularly update SSH keys and access keys

## Customization

### Change Terraform Version

Edit the workflow file:

```yaml
env:
  TF_VERSION: '1.5.0'  # Change to desired version
```

### Add More Workspaces

1. Create new tfvars file (e.g., `prod.tfvars`)
2. Update matrix in workflow:

```yaml
matrix:
  workspace: ['pi', 'wsl', 'prod']
```

### Modify Backend Configuration

If using different backend (not MinIO):

1. Update `backend.tf`
2. Update AWS credentials configuration in workflow
3. Adjust environment variables as needed

## Monitoring and Logs

- View workflow runs: Actions tab → Terraform Multi-Workspace Deployment
- Download artifacts: Plan files and outputs available for 5-30 days
- Check logs: Click on individual jobs for detailed logs

## Contributing

When making changes to infrastructure:

1. Create feature branch
2. Make changes
3. Push and create PR
4. Review plan output in PR comments
5. Merge to main after approval
6. Automatic deployment to both workspaces

## Support

For issues or questions:
1. Check workflow logs in Actions tab
2. Review Terraform error messages
3. Verify secrets configuration
4. Check network connectivity to targets
