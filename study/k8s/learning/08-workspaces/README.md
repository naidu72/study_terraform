# Lesson 8 — Workspaces

> **What we built:** One set of .tf files creating separate namespaces in dev and staging workspaces
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
08-workspaces/
├── provider.tf             → same as previous lessons
├── main.tf                 → uses terraform.workspace to name resources
├── outputs.tf              → shows namespace name and current workspace
└── terraform.tfstate.d/
    ├── dev/
    │   └── terraform.tfstate    ← state for dev workspace only
    └── staging/
        └── terraform.tfstate    ← state for staging workspace only
```

---

## Why Workspaces?

So far each lesson had its own directory and its own state file.
For environments that share identical infrastructure (just different sizes or names),
workspaces let you reuse the same `.tf` files with a completely separate state per environment.

```
Same .tf files  +  different workspace  =  different resources, different state
```

---

## `terraform.workspace` — The Built-in Variable

Every Terraform directory always has this value available:

```hcl
terraform.workspace    ← string containing the current workspace name
```

Default value is `"default"` until you create and switch to another workspace.

Used directly in `main.tf`:

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = "lesson8-${terraform.workspace}"    ← lesson8-dev, lesson8-staging, etc.
    labels = {
      environment = terraform.workspace
      managed_by  = "terraform"
    }
  }
}
```

---

## Workspace Commands

```bash
terraform workspace show              # show current workspace name
terraform workspace list              # list all workspaces (* marks current)
terraform workspace new dev           # create new workspace and switch to it
terraform workspace select staging    # switch to existing workspace
terraform workspace delete dev        # delete a workspace (must be empty/destroyed first)
```

---

## What Happened in This Lesson

```bash
terraform workspace show    → default

terraform workspace new dev
terraform apply             → creates lesson8-dev namespace
                            → state saved in terraform.tfstate.d/dev/

terraform workspace new staging
terraform apply             → creates lesson8-staging namespace
                            → state saved in terraform.tfstate.d/staging/

kubectl get namespaces | grep lesson8
# lesson8-dev
# lesson8-staging

terraform workspace select dev
terraform destroy           → destroys lesson8-dev only

kubectl get namespaces | grep lesson8
# lesson8-staging    ← untouched, different state file
```

---

## State File Structure

```
08-workspaces/
├── terraform.tfstate              ← "default" workspace state
└── terraform.tfstate.d/
    ├── dev/
    │   └── terraform.tfstate      ← dev workspace state
    └── staging/
        └── terraform.tfstate      ← staging workspace state
```

Each workspace tracks its own resources independently.
`terraform destroy` in `dev` never touches `staging` resources.

`.terraform/environment` — hidden file that records which workspace is currently active.

---

## Per-Environment Config with `locals`

`terraform.workspace` in locals lets you define different values per environment
without separate `.tf` files:

```hcl
locals {
  config = {
    default = {
      replica_count = 1
      team          = "dev-team"
    }
    dev = {
      replica_count = 1
      team          = "dev-team"
    }
    staging = {
      replica_count = 2
      team          = "platform"
    }
    prod = {
      replica_count = 5
      team          = "platform"
    }
  }

  current = local.config[terraform.workspace]
}
```

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = "app-${terraform.workspace}"
    labels = {
      team = local.current.team
    }
  }
}
```

Same code runs in all workspaces — different config applies automatically based on the active workspace.

---

## When to Use Workspaces vs Separate Directories

| | Workspaces | Separate directories |
|---|---|---|
| Same infrastructure structure | Yes | Yes |
| Different resources per env | No | Yes |
| Strict access control per env | No | Yes |
| Different teams own different envs | No | Yes |
| Simple, identical environments | Best fit | Overkill |

```
USE workspaces when:
  → dev/staging/prod are structurally identical, just different sizes or names
  → small teams managing all environments together

DO NOT use workspaces when:
  → prod has completely different resources than dev
  → different teams own different environments
  → you need strict IAM/RBAC per environment
  → use separate directories + separate state backends instead
```

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `terraform.workspace` | Built-in string with current workspace name — always available |
| `terraform workspace new` | Create a new workspace and switch to it |
| `terraform workspace select` | Switch to an existing workspace |
| `terraform workspace list` | List all workspaces, * marks the active one |
| `terraform.tfstate.d/` | Directory where workspace state files are stored |
| Workspace isolation | destroy in one workspace never affects another |
| Per-env config | Use `locals` map keyed by workspace name for per-environment values |

---

## What's Next — Lesson 9: Remote State Backend

**Problem this solves:**
Right now state files live on your local machine in `terraform.tfstate`.
If your teammate runs `terraform apply` from their machine, they have no state —
Terraform will try to recreate everything that already exists.

Remote state stores the state file in a shared location (S3, MinIO, Terraform Cloud)
so every team member and CI/CD pipeline works from the same state.

```hcl
terraform {
  backend "s3" {
    bucket   = "terraform-state"
    key      = "lesson9/terraform.tfstate"
    endpoint = "http://192.168.0.151:30900"   ← your MinIO
  }
}
```

→ **Lesson 9 directory:** `study/k8s/learning/09-remote-state/`
