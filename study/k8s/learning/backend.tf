terraform {
  # Partial backend config — static values only.
  # Credentials are passed at init time via -backend-config flags so they
  # never live in a .tf file that could be committed.
  #
  # Init command:
  #   terraform init \
  #     -backend-config="access_key=$(vault kv get -field=access_key_id secret/minio/credentials | tr -d '\n')" \
  #     -backend-config="secret_key=$(vault kv get -field=secret_access_key secret/minio/credentials | tr -d '\n')"
  backend "s3" {
    # ── MinIO bucket & state file location ────────────────────────
    bucket = "terraform-state"
    key    = "learning/count-foreach/terraform.tfstate"
    region = "us-east-1"   # MinIO ignores this, but Terraform requires it

    # ── MinIO endpoint ────────────────────────────────────────────────
    # LOCAL DEV: kubectl port-forward svc/minio-api-service 9000:9000 -n minio
    #   then use http://localhost:9000  (bypasses Cloudflare, avoids SigV4 header issue)
    #
    # CI (self-hosted runner on Pi): use internal cluster IP directly
    #   http://192.168.0.151:30900
    #
    # Why NOT https://s3api.naidu72.info:
    #   Cloudflare Tunnel strips headers that Go's AWS SDK includes in the
    #   SigV4 signature. AWS CLI (Python/boto3) signs fewer headers so it
    #   passes, but Terraform's backend fails with SignatureDoesNotMatch.
    endpoints = {
      s3 = "http://192.168.0.151:30900"
    }

    # ── Skip AWS-specific checks (not needed for MinIO) ───────────
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    # ── Path-style access required for MinIO ──────────────────────
    # Virtual-hosted style:  https://bucket.s3api.naidu72.info  ← MinIO doesn't support this
    # Path style:            https://s3api.naidu72.info/bucket   ← use this
    use_path_style = true

    # ── Disable workspace prefix ───────────────────────────────────
    # Default is "env:" which makes Terraform scan s3://bucket/env:/
    # Set to "" so the key is used as-is: learning/count-foreach/terraform.tfstate
    workspace_key_prefix = ""
  }
}
