#!/bin/bash
# Quick fix script for GitHub Actions backend issue

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║                  Applying GitHub Actions Backend Fix                        ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

cd /home/frontier/terraform/study_terraform

echo "🔍 Issue: GitHub Actions cannot access local MinIO (localhost:9000)"
echo "✅ Solution: Switch to local backend for CI/CD"
echo ""

echo "📋 Changes to be made:"
echo "  1. Disable S3-based workflow (terraform.yml)"
echo "  2. Activate local backend workflow (terraform-local-backend.yml)"
echo ""

read -p "Apply the fix? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "❌ Fix cancelled"
    exit 0
fi

echo ""
echo "🔧 Applying fix..."
echo ""

# Disable the S3-based workflow
if [ -f ".github/workflows/terraform.yml" ]; then
    echo "  ✓ Disabling S3-based workflow..."
    mv .github/workflows/terraform.yml .github/workflows/terraform-s3-backend.yml.disabled
    echo "    Renamed: terraform.yml → terraform-s3-backend.yml.disabled"
fi

# Verify local backend workflow exists
if [ ! -f ".github/workflows/terraform-local-backend.yml" ]; then
    echo "  ❌ Error: terraform-local-backend.yml not found!"
    exit 1
fi

echo "  ✓ Local backend workflow is active: terraform-local-backend.yml"
echo ""

# Show git status
echo "📊 Git status:"
git status --short
echo ""

# Commit changes
echo "💾 Committing changes..."
git add .github/workflows/
git add BACKEND_ISSUE_FIX.md
git add apply-backend-fix.sh

git commit -m "Fix: Use local backend for GitHub Actions (MinIO not accessible from cloud)"

echo ""
echo "✅ Fix applied successfully!"
echo ""

# Ask about pushing
read -p "Push to GitHub now? (y/n): " push_confirm

if [ "$push_confirm" = "y" ]; then
    echo ""
    echo "🚀 Pushing to GitHub..."
    git push origin main
    
    echo ""
    echo "✅ Pushed successfully!"
    echo ""
    echo "📊 Watch the workflow at:"
    echo "   https://github.com/naidu72/study_terraform/actions"
    echo ""
    echo "Or use: gh run watch --repo naidu72/study_terraform"
else
    echo ""
    echo "⚠️  Changes committed but not pushed."
    echo "   Push manually with: git push origin main"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 For more details, see: BACKEND_ISSUE_FIX.md"
echo ""
echo "🎉 Done!"
echo ""
