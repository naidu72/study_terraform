# Self-Hosted GitHub Actions Runner on WSL2

## What is a Self-Hosted Runner?

Instead of using GitHub's cloud runners, you can run the GitHub Actions workflow **on your own machine** (WSL2).

### Benefits:
- ✅ Direct access to your WSL2 Docker
- ✅ Direct access to your local MinIO
- ✅ No need to expose services publicly
- ✅ Faster (no network latency)
- ✅ Free (uses your own compute)

### Drawbacks:
- ⚠️ Your machine must be running
- ⚠️ Uses your machine's resources
- ⚠️ Less isolated than cloud runners

## Setup Self-Hosted Runner on WSL2

### Step 1: Navigate to GitHub Settings

Go to: https://github.com/naidu72/study_terraform/settings/actions/runners

Click: **New self-hosted runner**

### Step 2: Select Linux x64

Choose:
- Operating System: **Linux**
- Architecture: **x64**

### Step 3: Run Setup Commands in WSL2

GitHub will show you commands. Run them in your WSL2:

```bash
# Create a folder for the runner
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download the latest runner package
curl -o actions-runner-linux-x64-2.333.1.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.333.1/actions-runner-linux-x64-2.333.1.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-2.333.1.tar.gz

# Configure the runner
./config.sh --url https://github.com/naidu72/study_terraform --token YOUR_TOKEN_FROM_GITHUB

# Run the runner
./run.sh
```

**Note**: Replace `YOUR_TOKEN_FROM_GITHUB` with the token shown on the GitHub page.

### Step 4: Configure Runner

When prompted:

```
Enter the name of the runner [default hostname]: wsl2-runner
Enter any additional labels (ex. label-1,label-2): wsl2,local
Enter name of work folder [default _work]: _work
```

### Step 5: Update Workflow to Use Self-Hosted Runner

Edit `.github/workflows/terraform-local-backend.yml`:

```yaml
jobs:
  terraform-plan:
    name: Terraform Plan - ${{ matrix.workspace }}
    # Change this line:
    runs-on: ubuntu-latest
    # To this:
    runs-on: ${{ matrix.workspace == 'wsl' && 'self-hosted' || 'ubuntu-latest' }}
    
    strategy:
      matrix:
        workspace: ['pi', 'wsl']
```

This means:
- **WSL workspace**: Runs on your self-hosted runner (WSL2)
- **Pi workspace**: Runs on GitHub's cloud runner (can SSH to Pi)

### Step 6: Run as Service (Optional but Recommended)

To keep the runner running in the background:

```bash
cd ~/actions-runner

# Install as service
sudo ./svc.sh install

# Start service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

## Workflow Configuration for Mixed Runners

Create a new workflow that uses both cloud and self-hosted runners:

```yaml
name: Terraform Multi-Workspace (Mixed Runners)

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  terraform-plan-pi:
    name: Terraform Plan - Pi
    runs-on: ubuntu-latest  # Cloud runner
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.PI_SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.PI_HOST }} >> ~/.ssh/known_hosts
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan -var-file=pi.tfvars

  terraform-plan-wsl:
    name: Terraform Plan - WSL
    runs-on: self-hosted  # Your WSL2 machine
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan -var-file=wsl.tfvars
```

## Testing the Setup

After setting up the runner:

```bash
# Check if runner is online
# Go to: https://github.com/naidu72/study_terraform/settings/actions/runners

# Trigger a workflow
git commit --allow-empty -m "Test self-hosted runner"
git push origin main

# Watch the workflow
gh run watch --repo naidu72/study_terraform
```

## Troubleshooting

### Runner Not Showing Up

```bash
# Check runner status
cd ~/actions-runner
./run.sh

# Check service status (if installed as service)
sudo ./svc.sh status

# View logs
journalctl -u actions.runner.* -f
```

### Docker Permission Issues

```bash
# Add runner user to docker group
sudo usermod -aG docker $USER

# Restart runner
sudo ./svc.sh stop
sudo ./svc.sh start
```

### MinIO Not Accessible

```bash
# Check MinIO is running
docker ps | grep minio

# Test connection
curl http://localhost:9000/minio/health/live
```

## Security Considerations

### Self-Hosted Runner Security

⚠️ **Important**: Self-hosted runners should NOT be used for public repositories!

**Why?**
- Anyone can create a PR to your public repo
- Their code would run on your machine
- Security risk!

**Safe Usage**:
- ✅ Private repositories only
- ✅ Trusted contributors only
- ✅ Behind firewall
- ✅ Regular updates

### Recommendations

1. **Keep runner updated**:
   ```bash
   cd ~/actions-runner
   ./config.sh remove
   # Download latest version
   ./config.sh --url ... --token ...
   ```

2. **Use separate user** for runner:
   ```bash
   sudo useradd -m -s /bin/bash github-runner
   sudo su - github-runner
   # Setup runner as this user
   ```

3. **Limit permissions**:
   - Don't run as root
   - Use minimal Docker permissions
   - Restrict network access

## Alternative: Expose WSL2 via Tunnel

If you don't want a self-hosted runner, you can expose WSL2 Docker via SSH tunnel:

### Option A: ngrok (Easy)

```bash
# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok

# Setup SSH server in WSL2
sudo apt install openssh-server
sudo service ssh start

# Expose SSH via ngrok
ngrok tcp 22

# Use the ngrok URL in your workflow
# Example: tcp://0.tcp.ngrok.io:12345
```

### Option B: Cloudflare Tunnel (Free)

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Create tunnel
cloudflared tunnel create wsl2-tunnel

# Configure tunnel for SSH
cloudflared tunnel route dns wsl2-tunnel wsl2.yourdomain.com

# Run tunnel
cloudflared tunnel run wsl2-tunnel
```

## Comparison

| Solution | Pros | Cons | Complexity |
|----------|------|------|------------|
| **Self-Hosted Runner** | Direct access, fast, free | Machine must run | Medium |
| **ngrok Tunnel** | Easy setup, temporary | Costs for permanent | Low |
| **Cloudflare Tunnel** | Free, permanent | DNS setup needed | Medium |
| **Cloud Runner Only** | No setup, isolated | Can't access WSL2 | Low |

## Recommended Approach

**For Learning/Testing:**
- Use self-hosted runner on WSL2
- Simple setup, full control

**For Production:**
- Use cloud runners for Pi
- Consider moving WSL2 workload to cloud or Pi

## Summary

Self-hosted runner on WSL2:
1. ✅ Solves the WSL2 access problem
2. ✅ Direct access to local Docker and MinIO
3. ✅ Free and fast
4. ⚠️ Requires your machine to be running
5. ⚠️ Only for private repos (security)

**Next Step**: Set up self-hosted runner following Step 1-6 above.
