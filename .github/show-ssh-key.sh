#!/bin/bash
# Helper script to display SSH private key for GitHub Secrets

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║                    SSH Private Key for GitHub Secrets                       ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check for existing keys
echo "🔍 Checking for SSH keys..."
echo ""

SSH_KEYS=(
    "$HOME/.ssh/id_rsa"
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/pi_terraform"
)

FOUND_KEY=""

for key in "${SSH_KEYS[@]}"; do
    if [ -f "$key" ]; then
        echo "✅ Found: $key"
        
        # Test if this key works with Pi
        echo "   Testing connection to Pi..."
        if ssh -i "$key" -o BatchMode=yes -o ConnectTimeout=5 naidu@pi "echo 'Connection successful'" 2>/dev/null; then
            echo "   ✅ This key works with Pi!"
            FOUND_KEY="$key"
            break
        else
            echo "   ⚠️  This key doesn't work with Pi (or Pi is unreachable)"
        fi
    fi
done

echo ""

if [ -z "$FOUND_KEY" ]; then
    echo "❌ No working SSH key found for Pi"
    echo ""
    echo "Would you like to generate a new SSH key? (y/n)"
    read -r response
    
    if [ "$response" = "y" ]; then
        echo ""
        echo "Generating new SSH key..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/pi_terraform -N ""
        
        echo ""
        echo "✅ Key generated: ~/.ssh/pi_terraform"
        echo ""
        echo "Now copying public key to Pi..."
        ssh-copy-id -i ~/.ssh/pi_terraform.pub naidu@pi
        
        echo ""
        echo "Testing connection..."
        if ssh -i ~/.ssh/pi_terraform naidu@pi "echo 'Connection successful'"; then
            echo "✅ SSH key setup complete!"
            FOUND_KEY="$HOME/.ssh/pi_terraform"
        else
            echo "❌ Failed to connect to Pi. Please check:"
            echo "   1. Pi is powered on and connected to network"
            echo "   2. SSH service is running on Pi"
            echo "   3. Username 'naidu' is correct"
            exit 1
        fi
    else
        echo "Exiting..."
        exit 1
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Copy the following private key to GitHub Secrets"
echo ""
echo "Secret Name: PI_SSH_PRIVATE_KEY"
echo "Secret Value: (copy everything below, including BEGIN/END lines)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat "$FOUND_KEY"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Copy the entire key above (including BEGIN/END lines)"
echo "2. Go to: https://github.com/naidu72/study_terraform/settings/secrets/actions"
echo "3. Click 'New repository secret'"
echo "4. Name: PI_SSH_PRIVATE_KEY"
echo "5. Value: Paste the key"
echo "6. Click 'Add secret'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Other required secrets:"
echo ""
echo "AWS_ACCESS_KEY_ID = admin"
echo "AWS_SECRET_ACCESS_KEY = password"
echo "PI_HOST = pi"
echo ""
echo "Add these at the same URL above."
echo ""
