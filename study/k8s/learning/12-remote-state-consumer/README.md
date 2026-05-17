# Mini-Lesson E — terraform_remote_state

> **What we built:** Project B reads Project A's state from MinIO to deploy into its namespace
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
12-remote-state-consumer/
├── provider.tf   → same as previous lessons
├── backend.tf    → this project's own state in MinIO
├── main.tf       → data source reading lesson9 state + ConfigMap resource
└── README.md     → this file
```

---

## The Problem

Two Terraform projects. Project B needs a value from Project A.

**Without `terraform_remote_state` — hardcoded, fragile:**
```hcl
namespace = "lesson9-remote-state"   ← breaks if Project A renames the namespace
```

**With `terraform_remote_state` — reads the real value from state:**
```hcl
namespace = data.terraform_remote_state.lesson9.outputs.namespace_name
            ← always accurate, updates automatically when Project A changes
```

---

## How It Works

```
Project A (09-remote-state)                Project B (12-remote-state-consumer)
───────────────────────────                ─────────────────────────────────────
output "namespace_name" { }   ──┐
output "namespace_uid" { }      │
                                │
terraform apply                 │
  → state written to MinIO  ────┤
                                │
                                └──→  data "terraform_remote_state" reads state
                                       → outputs.namespace_name = "lesson9-remote-state"
                                       → outputs.namespace_uid  = "21c1cf0f-..."
                                      resource "kubernetes_config_map_v1" created
                                        in namespace: lesson9-remote-state
```

---

## `data "terraform_remote_state"` Block

```hcl
data "terraform_remote_state" "lesson9" {
  backend = "s3"

  config = {
    bucket               = "terraform-state"
    key                  = "learning/09-remote-state/terraform.tfstate"
    region               = "us-east-1"
    endpoints            = { s3 = "http://192.168.0.151:30900" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
    workspace_key_prefix        = ""
  }
}
```

- `backend` — must match Project A's backend type (`"s3"` for MinIO)
- `key` — exact path to Project A's state file in the bucket
- `config` — same connection settings as the backend, but inline

**IMPORTANT — credentials must NOT be hardcoded in `config {}`:**
```hcl
# WRONG — credentials in code = committed to git = security breach
config = {
  access_key = "my-key"      ← never do this
  secret_key = "my-secret"   ← never do this
}

# CORRECT — use environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
# Terraform picks them up automatically from environment
```

---

## Referencing Remote Outputs

```hcl
data.terraform_remote_state.LABEL.outputs.OUTPUT_NAME
                            ↑              ↑
                            your label     must be declared in Project A's outputs.tf
```

**The encapsulation rule applies here too:**
Only outputs declared in Project A's `outputs.tf` are readable.
Internal variables, locals, and resource attributes are not accessible.

---

## What Was Created

```hcl
resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "consumer-config"
    namespace = data.terraform_remote_state.lesson9.outputs.namespace_name
  }

  data = {
    source_namespace = data.terraform_remote_state.lesson9.outputs.namespace_name
    source_uid       = data.terraform_remote_state.lesson9.outputs.namespace_uid
  }
}
```

```bash
kubectl get cm -n lesson9-remote-state consumer-config -o yaml
# data:
#   source_namespace: lesson9-remote-state
#   source_uid: 21c1cf0f-7907-4e08-be89-7686ba523eda
```

Project A owns the namespace. Project B owns the ConfigMap inside it.
Neither project touches what the other owns.

---

## `terraform_remote_state` vs Data Source

| | `data "kubernetes_namespace_v1"` | `data "terraform_remote_state"` |
|---|---|---|
| Reads from | Real Kubernetes cluster | Terraform state file in MinIO/S3 |
| Gets | Current live state of a resource | Outputs declared by another Terraform project |
| Use when | Reading existing cluster resources | Sharing values between Terraform projects |

---

## Real World Pattern

```
platform-team/terraform/
  namespaces/     ← creates all namespaces, outputs their names
  networking/     ← creates VPCs, outputs subnet IDs

app-team/terraform/
  backend/        ← reads namespace from platform-team/namespaces state
  frontend/       ← reads namespace from platform-team/namespaces state
```

Each team manages their own resources. `terraform_remote_state` is the
contract between teams — no hardcoded values, no manual coordination.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `terraform_remote_state` | Read another project's outputs from its state file |
| `outputs.OUTPUT_NAME` | Access specific output — must be declared in the other project |
| Encapsulation | Only outputs are readable — internal values are private |
| Credentials | Never hardcode in config {} — use environment variables |
| Project A requirement | Must have `output {}` blocks and have run `terraform apply` |
| vs data source | Remote state reads Terraform outputs; data source reads live cluster |
