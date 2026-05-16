# Lesson 7 — Modules

> **What we built:** A reusable namespace module called twice to create two different namespaces
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
07-modules/
├── provider.tf                     ← root module — provider lives here only
├── main.tf                         ← root module — calls namespace module twice
├── outputs.tf                      ← root module — exposes module outputs
└── modules/
    └── namespace/
        ├── variables.tf            ← module inputs (name, team, environment)
        ├── main.tf                 ← module resources
        └── outputs.tf             ← module outputs (name, uid, labels)
```

---

## Why Modules?

Without modules — copy-paste the same block for every namespace:

```hcl
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name   = "lesson7-app"
    labels = { team = "backend", environment = "qa", managed_by = "terraform" }
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name   = "lesson7-monitoring"
    labels = { team = "platform", environment = "dev", managed_by = "terraform" }
  }
}
```

With modules — one definition, called multiple times with different inputs:

```hcl
module "app_namespace" {
  source      = "./modules/namespace"
  name        = "lesson7-app"
  team        = "backend"
  environment = "qa"
}

module "monitoring_namespace" {
  source      = "./modules/namespace"
  name        = "lesson7-monitoring"
  team        = "platform01"
  environment = "dev"
}
```

Same module code, different values — like calling a function twice with different arguments.

---

## Module Structure

### Module inputs — `modules/namespace/variables.tf`

```hcl
variable "name" {
  type = string          ← required, no default
}

variable "team" {
  type    = string
  default = "platform"   ← optional, has default
}

variable "environment" {
  type    = string
  default = "dev"
}
```

These are the **public interface** of the module — what callers must or can pass in.

### Module resources — `modules/namespace/main.tf`

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.name
    labels = {
      team        = var.team
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
```

Uses `var.*` to read the inputs. Private — callers cannot access this directly.

### Module outputs — `modules/namespace/outputs.tf`

```hcl
output "name" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}

output "uid" {
  value = kubernetes_namespace_v1.this.metadata[0].uid
}

output "labels" {
  value = kubernetes_namespace_v1.this.metadata[0].labels
}
```

These are the **public return values** — the only things the root module can read.

---

## Calling a Module — Root `main.tf`

```hcl
module "app_namespace" {
  source      = "./modules/namespace"   ← path to the module directory
  name        = "lesson7-app"           ← passes to var.name
  team        = "backend"               ← passes to var.team
  environment = "qa"                    ← passes to var.environment
}
```

**Format:**
```
module  "YOUR_LABEL"  {
          ↑ your name for this call — used in references and plan output
  source = "path or registry address"
  input  = value     ← matches variable names in the module's variables.tf
}
```

---

## Reading Module Outputs — Root `outputs.tf`

```hcl
output "app_namespace_env" {
  value = module.app_namespace.labels["environment"]
}
```

**Reference format:**
```
module.MODULE_LABEL.OUTPUT_NAME
       ↑              ↑
       your label     declared in module's outputs.tf
       from main.tf
```

**Comparison of all reference formats:**
```
var.name                          ← variable
local.name                        ← local
data.TYPE.LABEL.attribute         ← data source
module.LABEL.output_name          ← module output
```

---

## Encapsulation — The Most Important Module Rule

A module only exposes what its `outputs.tf` declares. Everything else is private.

```
module internals:
  var.*                        → PRIVATE — root cannot access
  local.*                      → PRIVATE — root cannot access
  resource attributes          → PRIVATE — root cannot access

module outputs:
  output "name" { }            → PUBLIC  — root accesses as module.label.name
```

**What does NOT work:**
```hcl
module.app_namespace.kubernetes_namespace_v1.this   ← BLOCKED, always
module.app_namespace.var.name                        ← BLOCKED, always
module.app_namespace.environment                     ← BLOCKED unless outputs.tf declares it
```

**The fix is always the same:** add the value to the module's `outputs.tf`.

---

## Provider — Where It Lives

The module has NO `provider.tf`. Only the root module declares providers.
All modules called from that root **inherit the provider automatically**.

```
root/provider.tf     ← ONE provider declaration for all modules
root/main.tf         ← calls module A and module B
modules/A/main.tf    ← uses the provider, never declares it
modules/B/main.tf    ← uses the provider, never declares it
```

---

## `terraform init` with Modules

```bash
terraform init
```

With modules, `terraform init` also registers the local module paths in
`.terraform/modules/modules.json`. You must re-run `terraform init` whenever
you add a new module or change the `source` path.

---

## `terraform console` — Exploring Module Outputs

When you're unsure what a module exposes, use the interactive console:

```bash
terraform console
```

```hcl
module.app_namespace                          # shows all outputs as an object
module.app_namespace.labels                   # shows the labels map
module.app_namespace.labels["environment"]    # shows single label value
```

Much faster than trial-and-error with `terraform plan`. Type `exit` to quit.

---

## Grouping Outputs — Cleaner with Many Modules

Instead of one output per value:

```hcl
output "app_namespace_name" { ... }
output "app_namespace_uid" { ... }
output "app_namespace_environment" { ... }
```

Group into one object per module:

```hcl
output "app_namespace" {
  value = {
    name        = module.app_namespace.name
    uid         = module.app_namespace.uid
    environment = module.app_namespace.labels["environment"]
  }
}
```

With 10+ modules, grouped outputs are much easier to read.

---

## Module Inputs — Strict Contract

A module only accepts what its `variables.tf` declares. Passing anything else is an error.

```hcl
module "app_namespace" {
  source      = "./modules/namespace"
  name        = "lesson7-app"
  owner       = "naidu72"    ← ERROR: module has no variable named "owner"
}
```

```
Error: Unsupported argument
  An argument named "owner" is not expected here.
```

---

## Adding Extra Labels from Root — `merge()` Pattern

By default the module has 3 fixed labels (`team`, `environment`, `managed_by`).
To allow callers to inject additional labels without hardcoding them in the module,
use the `merge()` + `extra_labels` pattern.

**Step 1 — add to `modules/namespace/variables.tf`:**

```hcl
variable "extra_labels" {
  type    = map(string)
  default = {}    ← empty by default, caller doesn't have to pass it
}
```

**Step 2 — update `modules/namespace/main.tf`:**

```hcl
labels = merge(
  {
    team        = var.team
    environment = var.environment
    managed_by  = "terraform"
  },
  var.extra_labels    ← merged on top — caller's labels added to the fixed ones
)
```

**Step 3 — root `main.tf` can now pass extra labels:**

```hcl
module "app_namespace" {
  source       = "./modules/namespace"
  name         = "lesson7-app"
  team         = "backend"
  environment  = "qa"
  extra_labels = {
    owner       = "naidu72"
    cost_center = "platform-001"
  }
}
```

**Result on the cluster:**
```
labels:
  team        = "backend"
  environment = "qa"
  managed_by  = "terraform"
  owner       = "naidu72"         ← injected from root
  cost_center = "platform-001"    ← injected from root
```

`merge()` combines both maps. If a key exists in both, the second map wins.
This is the standard pattern in real Terraform modules for flexible label passing.

---

## Root Module Has Its Own variables.tf and locals.tf

The root module is just another Terraform module — it can have its own
`variables.tf` and `locals.tf` completely independent from child modules.

```
root/variables.tf              ← root inputs (from -var, tfvars, CI/CD)
root/locals.tf                 ← root computed values
root/main.tf                   ← uses var.* and local.* to call child modules

modules/namespace/variables.tf ← module inputs (passed via module block)
modules/namespace/locals.tf    ← module's own private computed values
```

**These are NOT shared automatically.** Values must be passed explicitly:

```hcl
# root/locals.tf
locals {
  env = "qa"
}

# root/main.tf
module "app_namespace" {
  source      = "./modules/namespace"
  environment = local.env    ← explicitly passed, child module never sees local.env directly
}
```

The child module only sees `var.environment = "qa"` — it never has access to
the root's `local.env`. Every value crosses the boundary through module inputs.

---

## Connection to inventory-manager

The `inventory-manager` you reviewed at the start of this journey uses exactly this pattern:

```
environments/pi-cluster/main.tf   ← calls root module
main.tf                           ← calls namespace, postgresql, redis, frontend modules
modules/namespace/main.tf         ← creates kubernetes_namespace resource
modules/namespace/outputs.tf      ← returns name, id, labels
```

Every layer only sees what the layer below explicitly outputs. Now you can read that code and understand exactly why each file exists.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| Module | A reusable directory of .tf files — like a function |
| `source` | Path or registry address of the module directory |
| Module inputs | Variables in the module's `variables.tf` — the public interface |
| Module outputs | Outputs in the module's `outputs.tf` — the return values |
| `module.LABEL.output` | How to reference a module's output from the root |
| Encapsulation | Module internals are private — only outputs are visible outside |
| Provider inheritance | Root declares the provider — all modules inherit it automatically |
| `terraform init` | Must re-run when adding new modules or changing source paths |
| `terraform console` | Interactive shell to explore module outputs without guessing |

---

## What's Next — Lesson 8: Workspaces

**Problem this solves:**
Right now you have separate directories for dev/staging/prod.
Workspaces let you reuse the same `.tf` files with a completely separate state file per environment.

```bash
terraform workspace new staging
terraform workspace select staging
terraform apply    ← creates staging resources, separate state from dev
```

→ **Lesson 8 directory:** `study/k8s/learning/08-workspaces/`
