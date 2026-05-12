# Lesson 1 — Your First Terraform Resource

> **What we built:** A Kubernetes namespace using Terraform from absolute scratch
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes v3.1.0

---

## Files Created

```
00-first-steps/
├── provider.tf   → tells Terraform WHERE to connect (Pi cluster)
├── main.tf       → tells Terraform WHAT to create (a namespace)
└── README.md     → this file
```

---

## provider.tf — explained line by line

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"   # download from registry.terraform.io
      version = "~> 3.1"                 # use 3.1.x, not 4.x
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/pi-cluster"  # where the kubeconfig file lives
  config_context = "pi-k8s"             # which cluster inside that file
}
```

**Why two blocks?**
- `terraform { required_providers }` = what plugin to download
- `provider "kubernetes" { }` = how to connect using that plugin

---

## main.tf — explained line by line

```hcl
resource "kubernetes_namespace_v1" "my_first" {
  metadata {
    name = "my-first-namespace"
  }
}
```

**The resource format is always:**
```
resource  "TYPE"            "YOUR_LABEL"  {
           ↑                 ↑
           from the provider  your name for it inside Terraform
           (kubernetes_namespace_v1)      (can be anything)
}
```

**Why `kubernetes_namespace_v1` not `kubernetes_namespace`?**
- Provider 3.x renamed resources to match the Kubernetes API version (`v1`)
- `v1` = the Kubernetes API group for namespaces
- Always check the provider version on registry.terraform.io

---

## The 5 Commands You Ran

### `terraform init`
```bash
terraform init
```
- Downloads the kubernetes provider plugin into `.terraform/`
- Creates `.terraform.lock.hcl` to lock the exact version
- Think of it as `npm install` — run once when starting a project

```
.terraform/
└── providers/
    └── registry.terraform.io/hashicorp/kubernetes/3.1.0/
        └── terraform-provider-kubernetes   ← the actual binary
.terraform.lock.hcl                         ← version lock file
```

**`terraform init -upgrade`** = re-download and upgrade to newer version

---

### `terraform plan`
```bash
terraform plan
```
- Preview only — nothing is created
- Talks to the real cluster to detect drift
- Shows what WILL happen if you apply

**Reading the symbols:**
```
+  green   → will be CREATED
~  yellow  → will be UPDATED in place
-  red     → will be DESTROYED
-/+ red    → will be DESTROYED then RECREATED
```

---

### `terraform apply`
```bash
terraform apply
```
- Shows the plan again, asks for confirmation
- Type `yes` to proceed
- Actually creates/updates/destroys resources on the cluster
- Updates the state file after every change

---

### `terraform destroy`
```bash
terraform destroy
```
- Destroys EVERYTHING Terraform manages in this folder
- Asks for confirmation — type `yes`
- Updates state file (becomes empty)

---

### `terraform state list`
```bash
terraform state list
```
- Shows all resources Terraform is currently tracking
- Output after apply: `kubernetes_namespace_v1.my_first`
- Output after destroy: (empty)

---

## The Most Important Concept — State File

```
terraform.tfstate  =  Terraform's memory of what it created
```

Every `terraform apply` updates this file. It records:
- Which resources exist
- What their current values are
- What Terraform created vs what already existed

**The 3-way comparison on every `terraform plan`:**
```
.tf files      → what you WANT
state file     → what Terraform THINKS exists
real cluster   → what ACTUALLY exists

If all 3 agree  → Plan: 0 to add, 0 to change, 0 to destroy
If they differ  → Plan shows what needs to change
```

---

## Drift — Real World vs Desired State

**What happened:**
1. Terraform created `my-first-namespace` with no labels
2. Manually added a label with `kubectl`
3. Ran `terraform plan` — Terraform detected the manual label

**What the plan showed:**
```
~ kubernetes_namespace_v1.my_first   ← ~ yellow = will be modified
    ~ metadata {
        - labels = {                  ← - red = will be REMOVED
            - "my-manual-label" = "test"
          }
      }
```

**The golden rule:**
> Terraform owns what it creates. Any manual change will be undone on next `terraform apply`.

---

## `terraform plan -refresh=false` — The Dangerous Flag

```bash
terraform plan -refresh=false
```

**What it skips:**
```
Normal plan:           .tf files + state file + REAL CLUSTER  →  accurate result
-refresh=false plan:   .tf files + state file (only)          →  may miss drift
```

**The dangerous scenario:**
```
Teammate runs:  kubectl delete namespace my-first-namespace

terraform plan -refresh=false  →  Plan: 0 to add   ← WRONG — trusts stale state
terraform plan                 →  Plan: 1 to add   ← CORRECT — checked real cluster
```

**When to use `-refresh=false`:**
- Large infrastructure where refresh takes a long time
- You are 100% sure no drift exists
- Testing plan logic without touching the cluster

**When NOT to use it:**
- Before any real `terraform apply`
- When you suspect something changed outside Terraform

---

## How to Reference a Resource in Terraform

```hcl
# DECLARING (in main.tf):
resource "kubernetes_namespace_v1" "my_first" { }
          ↑ TYPE                   ↑ LABEL

# REFERENCING (anywhere else in your code):
kubernetes_namespace_v1.my_first.metadata[0].name
↑ TYPE                  ↑ LABEL  ↑ attribute path

# WRONG — do not include "resource" keyword when referencing:
resource.kubernetes_namespace_v1.my_first   ← WRONG
```

---

## Importing Existing Resources — `terraform import`

**Problem:** A namespace already exists on the cluster (created manually or by another tool).
Running `terraform apply` fails because Terraform tries to create what already exists.

**Solution:** Tell Terraform to adopt it into state without recreating it.

```bash
# CLI approach
terraform import kubernetes_namespace_v1.existing existing-app

# Format:
terraform import  TYPE.LABEL          REAL_RESOURCE_ID
#                 ↑ matches .tf        ↑ actual name on cluster
```

**Modern approach — import block (Terraform 1.5+):**
```hcl
import {
  to = kubernetes_namespace_v1.existing
  id = "existing-app"
}

resource "kubernetes_namespace_v1" "existing" {
  metadata {
    name = "existing-app"
  }
}
```
Run `terraform apply` — imports and manages in one step.
Remove the `import {}` block after apply — only needed once.

**After import:**
```bash
terraform state list                  # shows the imported resource
terraform state show TYPE.LABEL       # shows ALL attributes Terraform now knows
terraform plan                        # should show 0 changes if config matches
```

| Method | When to use |
|---|---|
| `terraform import` CLI | Quick one-off import |
| `import {}` block | Team workflows — visible in git, reviewable in PR |

---

## Removing Resources from Terraform Without Deleting Them — `terraform state rm`

**Problem:** You imported a resource but now you want Terraform to stop managing it
without destroying it on the cluster.

```bash
terraform state rm kubernetes_namespace_v1.existing
```

**What happens:**
```
State file:    resource is GONE      (Terraform forgets about it)
Real cluster:  resource still EXISTS  (completely untouched)

terraform plan → 0 changes           (Terraform no longer knows about it)
kubectl get namespace existing-app   → still there
```

**Import vs State RM — perfect opposites:**
```
terraform import    →  cluster resource added to state     (start managing)
terraform state rm  →  resource removed from state         (stop managing, keep alive)
```

| Command | Real cluster | State file |
|---|---|---|
| `terraform import` | Untouched | Resource added |
| `terraform state rm` | Untouched | Resource removed |
| `terraform destroy` | Resource deleted | Resource removed |

**Real world use cases:**
- `terraform import` — existing infra created before Terraform was adopted
- `terraform state rm` — hand off a resource to another team or another .tf file

---

## Handling Drift — 3 Ways to Deal with Manual Changes

**Scenario:** Terraform created a namespace. A user manually adds a label with `kubectl`.

```bash
kubectl label namespace my-first-namespace team=devops
terraform plan   # shows drift — label will be REMOVED
```

### Option 1 — Add it to your `.tf` file (Recommended)

Make the label officially Terraform-managed:

```hcl
resource "kubernetes_namespace_v1" "my_first" {
  metadata {
    name = "my-first-namespace"
    labels = {
      team = "devops"    # ← add this
    }
  }
}
```

```bash
terraform plan   # → 0 changes. Label now managed by Terraform forever.
```

Use when: **you own this label** and want Terraform to enforce it.

---

### Option 2 — `terraform apply -refresh-only`

Updates the **state file** to match real cluster. Does NOT update `.tf` files.

```bash
terraform apply -refresh-only
```

```
State file:  updated with team=devops label
.tf file:    still has no labels          ← not fixed
```

Next `terraform plan` will STILL show the label being removed.
This only syncs state temporarily — not a permanent fix.

Use when: **large infrastructure** where you want to sync state without any changes.

---

### Option 3 — `lifecycle ignore_changes`

Tell Terraform to permanently ignore a specific field:

```hcl
resource "kubernetes_namespace_v1" "my_first" {
  metadata {
    name = "my-first-namespace"
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]   # Terraform never touches labels
  }
}
```

```bash
terraform plan   # → 0 changes, even if labels differ on cluster
```

Use when: **another tool or team** manages that field (ArgoCD, a controller, ops team).
Terraform owns the resource but hands off control of specific fields.

---

### Comparison — Which option to use

| Option | .tf file | State file | Next plan |
|---|---|---|---|
| Add to `.tf` | Updated | Updated on apply | 0 changes — label enforced |
| `-refresh-only` | Unchanged | Updated | Still shows drift |
| `ignore_changes` | Has lifecycle block | Ignores field | 0 changes — field ignored forever |

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `provider` | Tells Terraform which system to talk to |
| `resource` | Declares what you want to exist |
| `terraform init` | Downloads plugins, sets up project |
| `terraform plan` | Safe preview — detects drift, shows changes |
| `terraform apply` | Makes changes real on the cluster |
| `terraform destroy` | Removes everything Terraform manages |
| `terraform import` | Adopt existing resource into state without recreating |
| `terraform state rm` | Stop managing a resource without deleting it |
| `terraform apply -refresh-only` | Sync state to match real cluster, no changes |
| `lifecycle ignore_changes` | Tell Terraform to never touch a specific field |
| State file | Terraform's memory — never edit manually |
| Drift | Real infra differs from desired state |
| `-refresh=false` | Skips cluster check — fast but risky |

---

## What's Next — Lesson 2: Variables

**Problem this solves:**
Right now `"my-first-namespace"` is hardcoded in `main.tf`.
What if you want to create 3 namespaces with different names?
You would have to copy the file 3 times — that's bad.

**Variables let you do this:**
```hcl
variable "namespace_name" {
  type    = string
  default = "my-first-namespace"
}

resource "kubernetes_namespace_v1" "my_first" {
  metadata {
    name = var.namespace_name   ← use the variable
  }
}
```

Now you can change the name without touching the resource definition.

→ **Lesson 2 directory:** `study/k8s/learning/02-variables/`
