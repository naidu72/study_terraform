#!/bin/bash
# Switch to local backend for local development

set -e

echo "🔄 Switching to local backend..."

# Backup current backend.tf
if [ -f backend.tf ]; then
    cp backend.tf backend.tf.s3.bak
    echo "✅ Backed up backend.tf → backend.tf.s3.bak"
fi

# Create local backend configuration
cat > backend.tf << 'EOF'
# Local backend for development
# State stored in ./terraform.tfstate
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF

echo "✅ Created backend.tf with local backend"
echo ""
echo "📝 Next steps:"
echo "   1. Run: terraform init -migrate-state"
echo "   2. Your state will be migrated to local file"
echo ""
echo "💡 To restore S3 backend later:"
echo "   mv backend.tf.s3.bak backend.tf"
echo "   terraform init -migrate-state"
