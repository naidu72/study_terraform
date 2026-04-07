# Self-Hosted Runner - Quick Start Guide

## 🎯 Goal

Run GitHub Actions workflows on YOUR WSL2 machine for direct access to Docker and MinIO.

## ⚡ Quick Setup (3 Commands)

### 1. Install Runner (~5 minutes)

```bash
cd /home/frontier/terraform/study_terraform
./setup-self-hosted-runner.sh
```

**What it does:**
- Downloads GitHub Actions runner
- Configures it for your repository
- Optionally installs as a service

**You'll need:**
- A token from GitHub (script will guide you)
- URL: https://github.com/naidu72/study_terraform/settings/actions/runners/new

### 2. Update Workflow (~2 minutes)

```bash
cd /home/frontier/terraform/study_terraform
./update-workflow-for-self-hosted.sh
```

**What it does:**
- Creates new workflow using self-hosted runner for WSL
- Keeps cloud runner for Pi
- Commits and pushes changes

### 3. Test It (~3 minutes)

```bash
git commit --allow-empty -m "Test self-hosted runner"
git push origin main
```

**Watch it run:**
```bash
gh run watch --repo naidu72/study_terraform
```

Or in browser: https://github.com/naidu72/study_terraform/actions

## 📊 How It Works

```
GitHub Workflow Triggered
         │
    ┌────┴────┐
    │         │
    ↓         ↓
  Pi Job    WSL Job
(Cloud)    (Your WSL2)
    │         │
    │         ├─> Direct Docker access
    │         ├─> Direct MinIO access
    │         └─> Local files
    │
    └─> SSH to Pi
```

## ✅ Benefits

- **Direct Access**: WSL workspace runs on your machine
- **No Backend Issues**: Direct access to MinIO
- **Fast**: No network latency
- **Free**: Uses your own compute
- **Hybrid**: Pi still uses cloud runner (can SSH from anywhere)

## 🔧 Managing the Runner

### Check Status

```bash
# If running as service
sudo systemctl status actions.runner.*

# If running manually
cd ~/actions-runner
./run.sh
```

### Start/Stop Service

```bash
# Start
sudo systemctl start actions.runner.*

# Stop
sudo systemctl stop actions.runner.*

# Restart
sudo systemctl restart actions.runner.*
```

### View Logs

```bash
# Service logs
journalctl -u actions.runner.* -f

# Or check runner logs
cat ~/actions-runner/_diag/Runner_*.log
```

### Check Online Status

Go to: https://github.com/naidu72/study_terraform/settings/actions/runners

You should see:
- **wsl2-runner** - Status: Idle (green) or Active (running job)

## 🐛 Troubleshooting

### Runner Not Online

```bash
# Check if running
ps aux | grep Runner.Listener

# Restart manually
cd ~/actions-runner
./run.sh
```

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again (or restart WSL)
```

### Terraform Not Found

```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### MinIO Not Accessible

```bash
# Check MinIO is running
docker ps | grep minio

# Test connection
curl http://localhost:9000/minio/health/live
```

## 📝 Workflow Configuration

The new workflow (`terraform-self-hosted.yml`) uses:

**For Pi workspace:**
```yaml
runs-on: ubuntu-latest  # GitHub cloud runner
```

**For WSL workspace:**
```yaml
runs-on: self-hosted  # Your WSL2 machine
```

## 🔒 Security Notes

### ⚠️ Important

Self-hosted runners should ONLY be used for:
- ✅ Private repositories
- ✅ Trusted contributors
- ✅ Behind firewall

**Never use for public repositories!** (Anyone can submit malicious code via PR)

### Best Practices

1. **Keep runner updated**
2. **Run as non-root user**
3. **Limit network access**
4. **Monitor logs regularly**
5. **Use separate user for runner**

## 🎓 Next Steps

After setup is complete:

1. **Verify runner is online**
   - Check: https://github.com/naidu72/study_terraform/settings/actions/runners

2. **Test with a commit**
   ```bash
   git commit --allow-empty -m "Test self-hosted runner"
   git push origin main
   ```

3. **Watch the workflow**
   ```bash
   gh run watch --repo naidu72/study_terraform
   ```

4. **Check deployed resources**
   ```bash
   # On WSL
   docker ps --filter "label=managed_by=terraform"
   
   # On Pi
   ssh naidu@pi "docker ps --filter 'label=managed_by=terraform'"
   ```

## 📚 Additional Resources

- **Setup Script**: `setup-self-hosted-runner.sh`
- **Update Script**: `update-workflow-for-self-hosted.sh`
- **Detailed Guide**: `SELF_HOSTED_RUNNER_SETUP.md`
- **GitHub Docs**: https://docs.github.com/en/actions/hosting-your-own-runners

## 🆘 Getting Help

If you encounter issues:

1. **Check runner logs**: `journalctl -u actions.runner.* -f`
2. **Check workflow logs**: https://github.com/naidu72/study_terraform/actions
3. **Verify runner status**: https://github.com/naidu72/study_terraform/settings/actions/runners
4. **Test locally**: Run terraform commands manually

## ✨ Summary

**Setup Time**: ~10 minutes total
- Install runner: 5 minutes
- Update workflow: 2 minutes
- Test: 3 minutes

**Result**: 
- ✅ WSL workspace runs on your machine
- ✅ Pi workspace runs on GitHub cloud
- ✅ Direct access to Docker and MinIO
- ✅ No backend configuration issues
- ✅ Fast and reliable

---

**Ready to start?**

```bash
cd /home/frontier/terraform/study_terraform
./setup-self-hosted-runner.sh
```

🚀 Let's go!
