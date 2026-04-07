#!/bin/bash
# Setup script for GitHub Actions secrets
# This script helps you configure the required secrets for the Terraform pipeline

set -e

REPO_OWNER="${GITHUB_REPOSITORY_OWNER:-your-github-username}"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-study_terraform}"

echo "================================================"
echo "GitHub Actions Secrets Setup for Terraform"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    echo ""
    echo "Or install via:"
    echo "  Ubuntu/Debian: sudo apt install gh"
    echo "  macOS: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_OWNER/$REPO_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✅ Set secret: $secret_name"
    else
        echo "❌ Failed to set secret: $secret_name"
    fi
}

# Get repository info
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""
read -p "Is this correct? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    read -p "Enter repository owner: " REPO_OWNER
    read -p "Enter repository name: " REPO_NAME
fi

echo ""
echo "================================================"
echo "Setting up secrets..."
echo "================================================"
echo ""

# S3/MinIO Backend Credentials
echo "1. S3/MinIO Backend Credentials"
echo "--------------------------------"
read -p "Enter AWS_ACCESS_KEY_ID (default: admin): " aws_access_key
aws_access_key=${aws_access_key:-admin}
set_secret "AWS_ACCESS_KEY_ID" "$aws_access_key"

read -sp "Enter AWS_SECRET_ACCESS_KEY (default: password): " aws_secret_key
echo ""
aws_secret_key=${aws_secret_key:-password}
set_secret "AWS_SECRET_ACCESS_KEY" "$aws_secret_key"

echo ""

# Pi SSH Configuration
echo "2. Raspberry Pi SSH Configuration"
echo "----------------------------------"
read -p "Enter Pi hostname or IP (default: pi): " pi_host
pi_host=${pi_host:-pi}
set_secret "PI_HOST" "$pi_host"

echo ""
echo "Enter SSH private key for Pi access:"
echo "(Paste the entire private key including BEGIN/END lines, then press Ctrl+D)"
echo ""

# Read multiline input for SSH key
pi_ssh_key=$(cat)

if [ -n "$pi_ssh_key" ]; then
    set_secret "PI_SSH_PRIVATE_KEY" "$pi_ssh_key"
else
    echo "⚠️  No SSH key provided. Skipping PI_SSH_PRIVATE_KEY"
fi

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Secrets configured:"
echo "  ✓ AWS_ACCESS_KEY_ID"
echo "  ✓ AWS_SECRET_ACCESS_KEY"
echo "  ✓ PI_HOST"
if [ -n "$pi_ssh_key" ]; then
    echo "  ✓ PI_SSH_PRIVATE_KEY"
fi
echo ""
echo "Next steps:"
echo "1. Verify secrets in GitHub: https://github.com/$REPO_OWNER/$REPO_NAME/settings/secrets/actions"
echo "2. Push your code to trigger the workflow"
echo "3. Monitor workflow runs in Actions tab"
echo ""
