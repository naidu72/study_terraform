#!/bin/bash
# Setup Self-Hosted GitHub Actions Runner on WSL2

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║           Self-Hosted GitHub Actions Runner Setup for WSL2                  ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

REPO_URL="https://github.com/naidu72/study_terraform"
RUNNER_VERSION="2.333.1"
RUNNER_DIR="$HOME/actions-runner"

echo "📋 Configuration:"
echo "  Repository: $REPO_URL"
echo "  Runner Version: $RUNNER_VERSION"
echo "  Install Directory: $RUNNER_DIR"
echo ""

# Check if runner already exists
if [ -d "$RUNNER_DIR" ]; then
    echo "⚠️  Runner directory already exists: $RUNNER_DIR"
    read -p "Remove existing runner and reinstall? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo "Removing existing runner..."
        cd "$RUNNER_DIR"
        if [ -f "./svc.sh" ]; then
            sudo ./svc.sh stop 2>/dev/null || true
            sudo ./svc.sh uninstall 2>/dev/null || true
        fi
        if [ -f "./config.sh" ]; then
            ./config.sh remove --token dummy 2>/dev/null || true
        fi
        cd ~
        rm -rf "$RUNNER_DIR"
    else
        echo "❌ Setup cancelled"
        exit 0
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Get Runner Token from GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Open this URL in your browser:"
echo "   https://github.com/naidu72/study_terraform/settings/actions/runners/new"
echo ""
echo "2. Select: Linux x64"
echo ""
echo "3. Copy the TOKEN from the 'Configure' section"
echo "   (It looks like: AAAA...ZZZZ)"
echo ""
read -p "Press Enter when you have the token ready..."
echo ""
read -sp "Paste the token here: " RUNNER_TOKEN
echo ""

if [ -z "$RUNNER_TOKEN" ]; then
    echo "❌ Error: No token provided"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Installing Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create runner directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

echo "📥 Downloading GitHub Actions Runner v$RUNNER_VERSION..."
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "📦 Extracting runner..."
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo "✅ Runner downloaded and extracted"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Configuring Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configure runner
./config.sh \
  --url "$REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "wsl2-runner" \
  --labels "wsl2,self-hosted,linux,x64" \
  --work "_work" \
  --replace

echo ""
echo "✅ Runner configured successfully!"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Installing as Service (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Install runner as a service (runs automatically)? (y/n): " install_service

if [ "$install_service" = "y" ]; then
    echo "Installing as service..."
    sudo ./svc.sh install
    sudo ./svc.sh start
    echo "✅ Service installed and started"
    echo ""
    echo "Service commands:"
    echo "  Start:   sudo ./svc.sh start"
    echo "  Stop:    sudo ./svc.sh stop"
    echo "  Status:  sudo ./svc.sh status"
else
    echo "⚠️  Skipping service installation"
    echo ""
    echo "To run the runner manually:"
    echo "  cd $RUNNER_DIR"
    echo "  ./run.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Runner Status:"
echo "  Name: wsl2-runner"
echo "  Labels: wsl2, self-hosted, linux, x64"
echo "  Location: $RUNNER_DIR"
echo ""
echo "🔍 Verify runner is online:"
echo "  https://github.com/naidu72/study_terraform/settings/actions/runners"
echo ""
echo "📝 Next Steps:"
echo "  1. Update workflow to use self-hosted runner"
echo "  2. Test with a commit"
echo ""
echo "Run this to update the workflow:"
echo "  cd /home/frontier/terraform/study_terraform"
echo "  ./update-workflow-for-self-hosted.sh"
echo ""
