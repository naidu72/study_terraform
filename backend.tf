# Option A — Local backend (start here)
# State stored in ./terraform.tfstate
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# ─────────────────────────────────────────────────────────────
# Option B — Switch to MinIO (S3-compatible, runs on your Pi)
# Run: docker run -p 9000:9000 minio/minio server /data
# Then create bucket "tf-state" in the MinIO console
# ─────────────────────────────────────────────────────────────
terraform {
  backend "s3" {
    bucket                      = "tf-state"
    key                         = "phase1-project/terraform.tfstate"
    region                      = "us-east-1"   # required but ignored by MinIO
    endpoint                    = "http://localhost:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    force_path_style            = true
    access_key = "admin"          # or use env vars instead
    secret_key = "password"
  }
}
