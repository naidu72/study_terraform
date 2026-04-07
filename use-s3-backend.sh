#!/bin/bash
# Switch back to S3 (MinIO) backend

set -e

echo "🔄 Switching to S3 (MinIO) backend..."

# Check if backup exists
if [ ! -f backend.tf.s3.bak ]; then
    echo "❌ Error: backend.tf.s3.bak not found!"
    echo "   Cannot restore S3 backend configuration."
    exit 1
fi

# Backup current backend.tf
if [ -f backend.tf ]; then
    cp backend.tf backend.tf.local.bak
    echo "✅ Backed up current backend.tf → backend.tf.local.bak"
fi

# Restore S3 backend
cp backend.tf.s3.bak backend.tf
echo "✅ Restored backend.tf from backup"

echo ""
echo "📝 Next steps:"
echo "   1. Make sure MinIO is running:"
echo "      docker ps | grep minio"
echo "   2. Run: terraform init -migrate-state"
echo "   3. Your state will be migrated to MinIO"
echo ""
echo "💡 To switch back to local backend:"
echo "   ./use-local-backend.sh"
