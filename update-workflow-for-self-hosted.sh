#!/bin/bash
# Update workflow to use self-hosted runner for WSL workspace

set -e

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                              ║"
echo "║            Update Workflow for Self-Hosted Runner (WSL)                     ║"
echo "║                                                                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

cd /home/frontier/terraform/study_terraform

echo "📋 This will update the workflow to:"
echo "  • Use self-hosted runner for WSL workspace"
echo "  • Use GitHub cloud runner for Pi workspace"
echo "  • Use local backend (no MinIO needed)"
echo ""

read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "❌ Cancelled"
    exit 0
fi

echo ""
echo "🔧 Creating new workflow..."

cat > .github/workflows/terraform-self-hosted.yml << 'WORKFLOW_EOF'
name: Terraform Multi-Workspace (Self-Hosted WSL)

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
  workflow_dispatch:
    inputs:
      workspace:
        description: 'Workspace to deploy (pi, wsl, or both)'
        required: true
        default: 'both'
        type: choice
        options:
          - both
          - pi
          - wsl
      action:
        description: 'Terraform action'
        required: true
        default: 'plan'
        type: choice
        options:
          - plan
          - apply
          - destroy

env:
  TF_VERSION: '1.5.0'
  WORKING_DIR: '.'

jobs:
  # Pi workspace - runs on GitHub cloud runner
  terraform-plan-pi:
    name: Terraform Plan - Pi
    runs-on: ubuntu-latest
    if: |
      (github.event_name != 'workflow_dispatch') ||
      (github.event.inputs.workspace == 'both') ||
      (github.event.inputs.workspace == 'pi')
    
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Setup SSH for Pi
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.PI_SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.PI_HOST }} >> ~/.ssh/known_hosts

      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        continue-on-error: true

      - name: Terraform Init
        run: terraform init

      - name: Select Workspace
        run: |
          terraform workspace select pi || terraform workspace new pi
          echo "Selected workspace: $(terraform workspace show)"

      - name: Terraform Validate
        run: terraform validate -no-color

      - name: Terraform Plan
        run: |
          terraform plan \
            -var-file="pi.tfvars" \
            -out=pi.tfplan \
            -no-color

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-pi
          path: ${{ env.WORKING_DIR }}/pi.tfplan
          retention-days: 5

  # WSL workspace - runs on self-hosted runner
  terraform-plan-wsl:
    name: Terraform Plan - WSL
    runs-on: self-hosted
    if: |
      (github.event_name != 'workflow_dispatch') ||
      (github.event.inputs.workspace == 'both') ||
      (github.event.inputs.workspace == 'wsl')
    
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        continue-on-error: true

      - name: Terraform Init
        run: terraform init

      - name: Select Workspace
        run: |
          terraform workspace select wsl || terraform workspace new wsl
          echo "Selected workspace: $(terraform workspace show)"

      - name: Terraform Validate
        run: terraform validate -no-color

      - name: Terraform Plan
        run: |
          terraform plan \
            -var-file="wsl.tfvars" \
            -out=wsl.tfplan \
            -no-color

      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-wsl
          path: ${{ env.WORKING_DIR }}/wsl.tfplan
          retention-days: 5

  # Apply for Pi
  terraform-apply-pi:
    name: Terraform Apply - Pi
    runs-on: ubuntu-latest
    needs: terraform-plan-pi
    if: |
      ((github.ref == 'refs/heads/main' && github.event_name == 'push') ||
       (github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'apply')) &&
      ((github.event_name != 'workflow_dispatch') ||
       (github.event.inputs.workspace == 'both') ||
       (github.event.inputs.workspace == 'pi'))
    
    environment:
      name: pi
    
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Setup SSH for Pi
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.PI_SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.PI_HOST }} >> ~/.ssh/known_hosts

      - name: Terraform Init
        run: terraform init

      - name: Select Workspace
        run: terraform workspace select pi

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan-pi
          path: ${{ env.WORKING_DIR }}

      - name: Terraform Apply
        run: terraform apply -auto-approve pi.tfplan

      - name: Terraform Output
        run: terraform output -json > pi-outputs.json

      - name: Upload Outputs
        uses: actions/upload-artifact@v4
        with:
          name: outputs-pi
          path: ${{ env.WORKING_DIR }}/pi-outputs.json
          retention-days: 30

  # Apply for WSL
  terraform-apply-wsl:
    name: Terraform Apply - WSL
    runs-on: self-hosted
    needs: terraform-plan-wsl
    if: |
      ((github.ref == 'refs/heads/main' && github.event_name == 'push') ||
       (github.event_name == 'workflow_dispatch' && github.event.inputs.action == 'apply')) &&
      ((github.event_name != 'workflow_dispatch') ||
       (github.event.inputs.workspace == 'both') ||
       (github.event.inputs.workspace == 'wsl'))
    
    environment:
      name: wsl
    
    defaults:
      run:
        working-directory: ${{ env.WORKING_DIR }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init

      - name: Select Workspace
        run: terraform workspace select wsl

      - name: Download Plan
        uses: actions/download-artifact@v4
        with:
          name: tfplan-wsl
          path: ${{ env.WORKING_DIR }}

      - name: Terraform Apply
        run: terraform apply -auto-approve wsl.tfplan

      - name: Terraform Output
        run: terraform output -json > wsl-outputs.json

      - name: Upload Outputs
        uses: actions/upload-artifact@v4
        with:
          name: outputs-wsl
          path: ${{ env.WORKING_DIR }}/wsl-outputs.json
          retention-days: 30
WORKFLOW_EOF

echo "✅ Created: .github/workflows/terraform-self-hosted.yml"
echo ""

# Disable other workflows
echo "🔧 Disabling other workflows..."

if [ -f ".github/workflows/terraform.yml" ]; then
    mv .github/workflows/terraform.yml .github/workflows/terraform.yml.disabled
    echo "  ✓ Disabled: terraform.yml"
fi

if [ -f ".github/workflows/terraform-local-backend.yml" ]; then
    mv .github/workflows/terraform-local-backend.yml .github/workflows/terraform-local-backend.yml.disabled
    echo "  ✓ Disabled: terraform-local-backend.yml"
fi

echo ""
echo "📊 Git status:"
git status --short
echo ""

read -p "Commit and push changes? (y/n): " commit_confirm

if [ "$commit_confirm" = "y" ]; then
    echo ""
    echo "💾 Committing changes..."
    git add .github/workflows/
    git commit -m "Use self-hosted runner for WSL workspace"
    
    echo ""
    read -p "Push to GitHub? (y/n): " push_confirm
    
    if [ "$push_confirm" = "y" ]; then
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
        echo "⚠️  Changes committed but not pushed"
        echo "   Push with: git push origin main"
    fi
else
    echo "⚠️  Changes not committed"
    echo "   Review with: git diff"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Workflow updated for self-hosted runner!"
echo ""
echo "📋 Configuration:"
echo "  • Pi workspace:  GitHub cloud runner (ubuntu-latest)"
echo "  • WSL workspace: Self-hosted runner (your WSL2)"
echo ""
echo "🎉 Done!"
echo ""
