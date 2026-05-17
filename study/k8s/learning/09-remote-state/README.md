# Lesson 9 — Remote State Backend

> **What we built:** Terraform state stored in MinIO (S3-compatible) instead of local disk
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1
> **Backend:** MinIO via NodePort `http://192.168.0.151:30900`

---

## Files Created

```
09-remote-state/
├── provider.tf   → same as previous lessons
├── backend.tf    → S3 backend pointing to MinIO
├── main.tf       → simple namespace resource
└── README.md     → this file
```

No `terraform.tfstate` in this directory — state lives in MinIO.

---

## Why Remote State?

Local state only works for solo development:

```
Problem 1 — Teammate runs terraform apply from their machine
            They have no local state → Terraform tries to recreate everything → conflict

Problem 2 — CI/CD pipeline runs terraform apply
            Pipeline has no local state → same problem

Problem 3 — Local state file deleted or corrupted
            No backup → Terraform has no memory of what it created
```

Remote state solves all three — one shared state file everyone reads from:

```
Your machine   ──┐
Teammate       ──┤──→  MinIO / S3  →  terraform.tfstate  (single source of truth)
CI/CD pipeline ──┘
```

---

## `backend.tf` — Every Line Explained

```hcl
terraform {
  backend "s3" {
    bucket   = "terraform-state"
    key      = "learning/09-remote-state/terraform.tfstate"
    region   = "us-east-1"
```

- `bucket` — MinIO bucket name (must exist before `terraform init`)
- `key` — path inside the bucket where the state file is stored
- `region` — required by the S3 protocol, MinIO ignores the value but it must be set

```hcl
    endpoints = {
      s3 = "http://192.168.0.151:30900"
    }
```

Points the AWS S3 client to MinIO instead of AWS. Uses NodePort IP — NOT the
Cloudflare ingress URL. See "Why not Cloudflare?" below.

```hcl
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
```

These 4 flags disable AWS-specific validation checks that MinIO does not support.
Without them, Terraform tries to call AWS endpoints that don't exist on MinIO.

```hcl
    use_path_style       = true
```

S3 supports two URL styles:
```
Virtual-hosted: https://bucket.s3.amazonaws.com/key   ← AWS default
Path-style:     http://192.168.0.151:30900/bucket/key  ← required for MinIO
```

```hcl
    workspace_key_prefix = ""
```

By default Terraform prefixes workspace state paths with `env:/`:
```
default: env:/learning/09-remote-state/terraform.tfstate   ← MinIO can't list this
```
Setting it to `""` removes the prefix:
```
default: learning/09-remote-state/terraform.tfstate        ← works correctly
```

---

## Credentials — Never in `backend.tf`

`backend.tf` is committed to git. Credentials in git = security breach.

Pass credentials at `terraform init` time:

```bash
terraform init \
  -backend-config="access_key=YOUR_ACCESS_KEY" \
  -backend-config="secret_key=YOUR_SECRET_KEY"
```

Get values from Vault:
```bash
vault kv get secret/minio/credentials
```

In CI/CD pipelines, inject as environment variables instead:
```bash
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
terraform init
```

---

## Why Not the Cloudflare Ingress URL?

The Cloudflare ingress (`https://s3api.naidu72.info`) causes a SigV4 signature mismatch:

```
Terraform's AWS SDK signs the Content-Length header as part of SigV4
Cloudflare Tunnel strips the Content-Length header from requests
Result: signature doesn't match → AccessDenied error
```

NodePort `http://192.168.0.151:30900` bypasses Cloudflare entirely — no header
stripping, SigV4 works correctly.

---

## Verifying State is in MinIO

```bash
# List state files in MinIO
mc ls myminio/terraform-state/learning/09-remote-state/
# [2026-05-16] 1.3KiB STANDARD terraform.tfstate

# Confirm no local state file exists
ls *.tfstate 2>/dev/null || echo "no local state file"
# no local state file

# State list reads from MinIO
terraform state list
# kubernetes_namespace_v1.this
```

---

## State Locking

When Terraform runs `plan` or `apply`, it locks the state file so no other
Terraform process can modify it at the same time. MinIO supports S3 DynamoDB-style
locking — prevents two people from running `terraform apply` simultaneously and
corrupting the state.

---

## Bucket Versioning — Safety Net

MinIO bucket versioning keeps previous versions of the state file.
If state gets corrupted, you can restore the last good version.

```bash
# Enable versioning with mc CLI (requires admin credentials)
mc version enable myminio/terraform-state
```

This was enabled on your bucket — every `terraform apply` creates a new version
of the state file in MinIO.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| Remote backend | Stores state in shared location — team and CI/CD all use same state |
| `backend "s3"` | Works with any S3-compatible storage — AWS S3, MinIO, GCS |
| `key` | Path inside the bucket for this project's state file |
| `use_path_style` | Required for MinIO — uses `/bucket/key` URL format |
| `workspace_key_prefix = ""` | Removes `env:/` prefix that MinIO can't list |
| `-backend-config` | Pass credentials at init time — never write them in backend.tf |
| NodePort vs Cloudflare | Cloudflare drops Content-Length → SigV4 fails → use NodePort directly |
| `mc ls` | Verify state file exists in MinIO |
| Bucket versioning | Previous state versions kept — recoverable if corrupted |

---

## What's Next — Lesson 10: Putting It All Together

You have now learned every core Terraform concept:

| Lesson | Concept |
|---|---|
| 1 | Resources, state, drift, import |
| 2 | Variables |
| 3 | Locals |
| 4 | Data sources |
| 5 | Lifecycle rules |
| 6 | Outputs |
| 7 | Modules |
| 8 | Workspaces |
| 9 | Remote state ✓ |

Lesson 10 combines everything — build a production-style module with remote state,
variables, locals, outputs, lifecycle rules, and data sources working together.
